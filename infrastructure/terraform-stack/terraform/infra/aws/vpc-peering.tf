# VPC Peering Connections (설정 기반 동적 생성)
resource "aws_vpc_peering_connection" "this" {
  for_each = try(local.config.vpc_peering.enabled, false) ? {
    for conn in try(local.config.vpc_peering.connections, []) : conn.name => conn
  } : {}

  vpc_id        = module.vpc.vpc_id
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = each.value.peer_vpc_id

  # Cross-region peering인 경우 peer_region 설정
  peer_region = data.aws_region.current.name != each.value.peer_region ? each.value.peer_region : null

  # 같은 리전인 경우에만 auto_accept 사용 가능
  auto_accept = data.aws_region.current.name == each.value.peer_region ? true : false

  tags = merge(local.tags, {
    Name = format("%s-%s-peering", local.prefix, each.value.name)
    Type = "vpc-peering"
  })
}

# Cross-region peering의 경우 상대방 리전에서 수락
resource "aws_vpc_peering_connection_accepter" "this" {
  for_each = try(local.config.vpc_peering.enabled, false) ? {
    for name, conn in {
      for conn in try(local.config.vpc_peering.connections, []) : conn.name => conn
    } : name => conn
    if data.aws_region.current.name != conn.peer_region && conn.peer_region == "us-east-1"
  } : {}

  provider                  = aws.virginia
  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.key].id
  auto_accept               = true

  tags = merge(local.tags, {
    Name = format("accept-%s-%s-peering", local.prefix, each.key)
    Type = "vpc-peering"
  })
}

# Current VPC -> Peer VPC 라우팅 규칙
resource "aws_route" "to_peer" {
  for_each = try(local.config.vpc_peering.enabled, false) ? {
    for route_key, route_value in merge([
      for conn_name, conn in {
        for conn in try(local.config.vpc_peering.connections, []) : conn.name => conn
        } : {
        for rt_id in module.vpc.private_route_table_ids :
        "${conn_name}-${rt_id}" => {
          conn_name = conn_name
          rt_id     = rt_id
          peer_cidr = conn.peer_cidr
        }
      }
    ]...) : route_key => route_value
  } : {}

  route_table_id            = each.value.rt_id
  destination_cidr_block    = each.value.peer_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.value.conn_name].id
}

# Cross-region peering의 경우 us-east-1(Datadog) -> Current VPC 라우팅
resource "aws_route" "from_virginia" {
  for_each = try(local.config.vpc_peering.enabled, false) ? {
    for name, conn in {
      for conn in try(local.config.vpc_peering.connections, []) : conn.name => conn
    } : name => conn
    if data.aws_region.current.name != conn.peer_region && conn.peer_region == "us-east-1"
  } : {}

  provider                  = aws.virginia
  route_table_id            = data.aws_vpc.virginia.main_route_table_id
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.key].id
}


