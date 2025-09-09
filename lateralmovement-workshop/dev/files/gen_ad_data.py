import csv
from faker import Faker
import random
import yaml
import argparse
import string
from pyfiglet import Figlet

# Initialize Faker
fake = Faker()
Faker.seed(0)

def generate_password(length=15):
    """Generate a random password."""
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))

def generate_data(domain, num_users=10, admin_count=2, ou_ad_group_mapping=None):
    """Generate AD data with logical group assignments and random passwords."""
    if not ou_ad_group_mapping:
        ou_ad_group_mapping = {
            "Sales": "Sales",
            "Engineering": "Engineering",
            "HR": "HR",
            "IT": "IT",
            "Accounting": "Accounting"
        }

    ous = list(ou_ad_group_mapping.keys())
    ad_groups = list(ou_ad_group_mapping.values())
    ad_groups.append("Domain Admins")

    users = []
    for _ in range(num_users):
        ou = random.choice(ous)
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = f"{first_name.lower()}.{last_name.lower()}@{domain}"  # Email format
        username = f"{first_name[0].lower()}{last_name.lower()}"  # Username format

        user = {
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "password": generate_password(),
            "ou": ou,
            "ad_groups": [ou_ad_group_mapping[ou]]
        }
        users.append(user)

    for _ in range(admin_count):
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = f"{first_name.lower()}.{last_name.lower()}@{domain}"  # Email format
        username = f"{first_name[0].lower()}{last_name.lower()}"  # Username format

        user = {
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "password": generate_password(),
            "ou": None,
            "ad_groups": ["Domain Admins"]
        }
        users.append(user)

    return {"ous": ous, "ad_groups": ad_groups, "users": users}

def write_csv(users, domain):
    """Write users to a CSV file."""
    csv_filename = f"ad_data_{domain}.csv"
    with open(csv_filename, mode="w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=["username", "first_name", "last_name", "email", "password", "ou", "ad_groups"])
        writer.writeheader()
        for user in users:
            writer.writerow({
                "username": user["username"],
                "first_name": user["first_name"],
                "last_name": user["last_name"],
                "email": user["email"],
                "password": user["password"],
                "ou": user["ou"] if user["ou"] else "None",
                "ad_groups": ", ".join(user["ad_groups"])
            })
    print(f"CSV file successfully generated: {csv_filename}")


def main():
    # Create argument parser
    parser = argparse.ArgumentParser(description="Generate AD data for a specified domain.")
    parser.add_argument("--domain", required=True, help="The domain name for the AD environment (e.g., sandbox.pwnzone.lab)")
    parser.add_argument("--usercount", default=20, type=int)
    parser.add_argument("--admincount", default=2, type=int)
    args = parser.parse_args()
    
    # Extract arguments
    domain = args.domain.replace(".com", "")  # Sanitize domain input
    usercount = args.usercount
    admincount = args.admincount


    # Generate ASCII Art
    fig = Figlet(font="slant")
    print(fig.renderText("ANSIBLE AD POPULATOR"))
    print("-" * 50)
    print("by @jfmaes")
    print("-" * 50)

    # Extract domain and generate data
    data = generate_data(domain=domain, num_users=usercount, admin_count=admincount)

    # Save to file
    output_file = f"ad_data_{domain}.yml"
    with open(output_file, "w") as file:
        yaml.dump(data, file, default_flow_style=False)
    
    print(f"\nData successfully generated and saved to: {output_file}")
    
 # Save CSV file
    write_csv(data["users"], domain)
    
if __name__ == "__main__":
    main()
