import secrets
import os
import sys

def update_secret_key():
# Generate a random secret key
    secret_key = secrets.token_hex(16)

# Read the existing .env file
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_path = os.path.join(script_dir, '..', '.env')
    env_path = os.path.abspath(env_path)
    lines = []
    if os.path.exists(env_path):
        with open(env_path, 'r') as env_file:
            lines = env_file.readlines()
    else:
        print(f"Error: .env file not found at {env_path}. Aborting.")
        sys.exit(1)

# Write updated list to new_lines
    found = False
    new_lines = []
    for line in lines:
        if line.startswith('SECRET_KEY='):
            new_lines.append(f'SECRET_KEY={secret_key}\n')
            found = True
        else:
            new_lines.append(line)

# Ensure correct formatting
    if not found:
        if new_lines and not new_lines[-1].endswith('\n'):
            new_lines[-1] += '\n'
        new_lines.append(f'SECRET_KEY={secret_key}\n')
        print("SECRET_KEY added to the end of the .env file.")
    else:
        response = input("This will overwrite or add a SECRET_KEY in the .env file. Continue? [y/N]: ")
        if response.strip().lower() != 'y':
            print("Aborted by user.")
            sys.exit(0)

    with open(env_path, 'w') as env_file:
        env_file.writelines(new_lines)

if __name__ == "__main__":
    update_secret_key()
