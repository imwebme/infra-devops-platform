import pandas as pd
import datetime
import json
from bson import ObjectId
import pipeline as pl
from pytz import timezone
import seaborn as sns
import matplotlib.pyplot as plt
from operator import attrgetter
import matplotlib.colors as mcolors
from datetime import timedelta


from functools import reduce


def merge_list(index ,df_list) :
    return reduce(lambda left,right: pd.merge(left,right,on=[index], how='outer'), df_list)

def n_days_before_today_string(n_days=0):
    oneDay = datetime.timedelta(days=1)
    return str(datetime.datetime.now(tz=timezone('Asia/Seoul')).date() - (n_days) * oneDay)

def n_days_before_today_datetime(n_days=0):
    oneDay = datetime.timedelta(days=1)
    date = datetime.datetime.now(tz=timezone('Asia/Seoul')).date() - (n_days) * oneDay
    return datetime.datetime(date.year, date.month, date.day,0,0,0)

def getTime(n_days):
    oneDay = datetime.timedelta(days=n_days)
    return (
        datetime.datetime.now(tz=timezone("Asia/Seoul")).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        - oneDay
    )
    
def get_retention(df, ab = 'all', tag = 'total', fileName = 'total') :
    for timeFrame in ['D']: # 'D' : day, W': week, 'M': month
        df['timeGroup'] = df['loggedDate_x'].dt.to_period(timeFrame)
        df['cohort'] = df.groupby('userId')['loggedDate_y'].transform('min').dt.to_period(timeFrame)
        df_cohort = df.groupby(['cohort', 'timeGroup']).agg(n_users=('userId', 'nunique')).reset_index(drop=False)
        df_cohort['period_number'] = (df_cohort['timeGroup'] - df_cohort['cohort']).apply(attrgetter('n'))

        cohort_pivot = df_cohort.pivot_table(index='cohort', columns='period_number', values='n_users')
        cohort_size = cohort_pivot.iloc[:,0]
        retention_matrix = cohort_pivot.divide(cohort_size, axis=0)

        print(retention_matrix)
        with sns.axes_style('white'):
            fig, ax = plt.subplots(1, 2, figsize=(16, 12), sharey=True, gridspec_kw={'width_ratios': [1, 11]})

            # retention matrix
            sns.heatmap(retention_matrix,
                       mask=retention_matrix.isnull(),
                       annot=True,
                       fmt='.0%',
    #                    cmap='Greens',
                       cmap='RdYlGn',
                       ax=ax[1],
                       annot_kws={'size': 12},
                       vmin=0,
                       vmax=0.7,
                    cbar=False,
                       )
            if timeFrame == 'M': 
                title = 'Monthly Cohorts_' + ab + tag
            elif timeFrame == 'W': 
                title = 'Weekly Cohorts_' + ab + tag
            elif timeFrame =='D':
                title = 'DailyCohorts_' + ab + tag
            else: 
                raise ValueError('wrong timeFrame')

            ax[1].set_title(title, fontsize=16)
            ax[1].set(xlabel='# of periods',
                     ylabel='')

            # cohort size
            cohort_size_df = pd.DataFrame(cohort_size).rename(columns={0: 'cohort_size'})
            white_cmap = mcolors.ListedColormap('white')
            sns.heatmap(cohort_size_df,
                       annot=True,
                       cbar=False,
                       fmt='g',
                       cmap=white_cmap,
                       ax=ax[0])

            fig.tight_layout()
            file = f'/tmp/retention_{fileName}.png'
            plt.savefig(file)
            return file

def plot_graphs(dataframe):
    plt.figure(figsize=(14, 8))

    # 세션 수를 시각화
    plt.subplot(3, 1, 1)
    plt.plot(dataframe.index, dataframe['Avg Session Count'], marker='o', color='b', label='Avg Session Count')
    plt.title('Avg Session Count Over Time')
    plt.xlabel('Date')
    plt.ylabel('Avg Session Count')
    plt.grid(True)
    plt.ylim(0, dataframe['Avg Session Count'].max() * 1.1)  # Y축이 0에서 시작하도록 설정

    plt.legend()

    # 평균 세션 지속 시간을 시각화
    plt.subplot(3, 1, 2)
    plt.plot(dataframe.index, dataframe['Avg Session Duration (Min)'], marker='o', color='g', label='Avg Session Duration')
    plt.title('Avg Session Duration Over Time')
    plt.xlabel('Date')
    plt.ylabel('Avg SessionDuration (minutes)')
    plt.grid(True)
    plt.ylim(0, dataframe['Avg Session Duration (Min)'].max() * 1.1)  # Y축이 0에서 시작하도록 설정

    plt.legend()

    # 총 세션 지속 시간을 시각화
    plt.subplot(3, 1, 3)
    plt.plot(dataframe.index, dataframe['Avg Daily Total Duration (Min)'], marker='o', color='r', label='Avg Daily Total Duration')
    plt.title('Avg Daily Total Duration Over Time')
    plt.xlabel('Date')
    plt.ylabel('Avg Daily Total Duration (minutes)')
    plt.grid(True)
    plt.ylim(0, dataframe['Avg Daily Total Duration (Min)'].max() * 1.1)  # Y축이 0에서 시작하도록 설정

    plt.legend()

    plt.tight_layout()
    plt.tight_layout()
    file = f'almart_engagement.png'
    plt.savefig(file)
    return file

def getEngagement(item):
    # 초기화
    sessionCount = 0  # 세션 수를 저장하는 변수
    totalDuration = timedelta()  # 모든 세션의 총 지속 시간을 저장하는 변수
    sessionDurationList = []  # 각 세션의 지속 시간을 저장하는 리스트

    lastLog = None  # 이전 로그 항목을 저장하는 변수
    sessionDuration = timedelta()  # 현재 세션의 지속 시간을 저장하는 변수

    # 로그 항목 순회
    for log in item:
        if lastLog is None:
            # 첫 번째 로그 항목일 경우 초기화 및 세션 수 증가
            lastLog = log
            sessionCount += 1
            continue

        # 현재 로그와 이전 로그 사이의 시간 차이를 계산
        diff = log['createdAt'] - lastLog['createdAt']

        # 시간 차이가 5분보다 크면 새로운 세션 시작
        if diff > timedelta(minutes=5):
            sessionCount += 1  # 세션 수 증가
            sessionDurationList.append(sessionDuration)  # 현재 세션 지속 시간을 리스트에 추가
            totalDuration += sessionDuration  # 총 지속 시간에 현재 세션 지속 시간을 더함
            sessionDuration = timedelta()  # 현재 세션 지속 시간 초기화
        else:
            sessionDuration += diff  # 같은 세션으로 간주하여 시간 차이를 세션 지속 시간에 더함

        # 마지막 로그를 현재 로그로 갱신
        lastLog = log

    # 마지막 세션 지속 시간을 리스트와 총 지속 시간에 추가
    totalDuration += sessionDuration
    sessionDurationList.append(sessionDuration)

    # 평균 세션 지속 시간을 분 단위로 계산
    if sessionCount > 0:
        averageSessionDuration = sum((sd.total_seconds() for sd in sessionDurationList)) / (sessionCount * 60)
    else:
        averageSessionDuration = 0

    # 소수점 둘째 자리까지 제한
    averageSessionDuration = round(averageSessionDuration, 2)
    totalDurationMinutes = round(totalDuration.total_seconds() / 60, 2)

    # 결과를 딕셔너리 형태로 반환
    return {
        'sessionCount': sessionCount,  # 총 세션 수
        'sessionDurationList': sessionDurationList,  # 각 세션의 지속 시간 리스트
        'averageSessionDuration': averageSessionDuration,  # 평균 세션 지속 시간 (분)
        'totalDuration': totalDurationMinutes  # 총 세션 지속 시간 (분)
    }
