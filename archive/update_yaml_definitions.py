import yaml
import sys

def update_definitions(yaml_file_path, output_file_path):
    """
    Updates the `definition` field in each level to match the corresponding `code` value.

    Parameters:
        yaml_file_path (str): Path to the input YAML file.
        output_file_path (str): Path to save the updated YAML file.
    """
    try:
        # Load the YAML file
        with open(yaml_file_path, 'r') as file:
            data = yaml.safe_load(file)

        # Update each `definition` value to match its `code` value
        for attribute in data:
            for level in attribute.get('levels', []):
                level['definition'] = level['code']

        # Save the updated YAML file
        with open(output_file_path, 'w') as updated_file:
            yaml.dump(data, updated_file, default_flow_style=False)

        print(f"Updated YAML file has been saved to: {output_file_path}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python update_yaml_definitions.py <input_yaml_file> <output_yaml_file>")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        update_definitions(input_file, output_file)

