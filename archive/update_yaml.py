import yaml

def update_definitions(file_path):
    with open(file_path, 'r') as file:
        data = yaml.safe_load(file)

    for item in data:
        if 'attribute' in item:
            for level in item['attribute'].get('levels', []):
                level['definition'] = level['code']

    with open(file_path, 'w') as file:
        yaml.safe_dump(data, file)

if __name__ == "__main__":
    file_path = '/home/srearl/localRepos/knb-lter-cap.652/neighborhood_characteristics_factors.yaml'
    update_definitions(file_path)
    print(f"Updated definitions in {file_path}")
