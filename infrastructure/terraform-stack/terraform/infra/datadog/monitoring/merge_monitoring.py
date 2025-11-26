from ruamel.yaml import YAML
import os
import glob

SERVICES_DIR = os.path.join(os.path.dirname(__file__), 'services')
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), 'monitoring.yaml')

def main():
    backend = []
    for path in sorted(glob.glob(os.path.join(SERVICES_DIR, '*.yaml'))):
        with open(path, encoding='utf-8') as f:
            data = YAML(typ='safe').load(f)
            backend.append(data)
    result = {'owners': {'backend': backend}}
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)  # sequence=4로 리스트 들여쓰기 조정
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        yaml.dump(result, f)
    print(f"Merged {len(backend)} service yamls into monitoring.yaml!")

if __name__ == '__main__':
    main() 