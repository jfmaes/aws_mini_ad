import boto3
import argparse

def wait_until_image_exists(ec2, _id):
    """Wait for the AMI to become available."""
    ec2.Image(_id).wait_until_exists(Filters=[{'Name': 'state', 'Values': ['available']}])

def create_snapshot(region_name, name_prefix, version_tag):
    """Create snapshots (AMIs) of instances based on a name prefix."""
    ec2 = boto3.resource('ec2', region_name=region_name)
    ec2_client = boto3.client('ec2', region_name=region_name)

    # Filter instances by name prefix (SEC565) and exclude bastion
    filters = [{'Name': 'tag:Name', 'Values': [f"{name_prefix}*"]}]
    instances = ec2.instances.filter(Filters=filters)

    images = []
    for i in instances:
        # Get the Name tag of the instance
        instance_name = ''
        if 'Tags' in i.meta.data:
            instance_name = next((tag['Value'] for tag in i.meta.data['Tags'] if tag['Key'] == 'Name'), '')

        # Skip instances with 'bastion' in the name
        if 'bastion' in instance_name.lower():
            print(f"Skipping bastion instance: {instance_name}")
            continue
        
        name = f"AMI-{instance_name}-{version_tag}"
        print(f"Creating snapshot for {instance_name}...")
        resp = ec2_client.create_image(InstanceId=i.id, Name=name)
        image_id = resp["ImageId"]
        images.append(image_id)
        ec2.Image(image_id).create_tags(
            Tags=[
                {'Key': 'Name', 'Value': name},
                {'Key': 'VersionTag', 'Value': version_tag}
            ]
        )

    for ami_id in images:
        wait_until_image_exists(ec2, ami_id)

    return images

def make_public(ami_ids, region_name):
    """Make AMIs public by modifying their launch permissions."""
    ec2 = boto3.resource('ec2', region_name=region_name)
    for ami_id in ami_ids:
        ami = ec2.Image(ami_id)
        ami.modify_attribute(Attribute='launchPermission', LaunchPermission={
            'Add': [{'Group': 'all'}]
        })
        print(f"AMI {ami_id} made public")

def validate_version_tag(value):
    """Validate the version tag length."""
    if len(value) > 20 or len(value) < 1:
        raise argparse.ArgumentTypeError("version tag needs to have a length between 1 and 20")
    return value

if __name__ == "__main__":

    # Command line argument parsing
    epilog = """Example command: snapshot.py --region us-west-1 --name-prefix SEC565 --tag v0.1 --public"""

    parser = argparse.ArgumentParser(description='Snapshot EC2 instances with specific name prefix', epilog=epilog)
    parser.add_argument('--region', dest='region', required=True, help='AWS region to operate in')
    parser.add_argument('--name-prefix', dest='name_prefix', required=True, help='Prefix of EC2 instance names')
    parser.add_argument('--tag', dest='version_tag', type=validate_version_tag, required=True, help='Version tag for snapshots')
    parser.add_argument('--public', dest='make_public', action='store_true', help="Make images public after creation")
    args = parser.parse_args()

    print("Creating snapshot and waiting for images to become available ...")
    ami_ids = create_snapshot(args.region, args.name_prefix, args.version_tag)

    # Optionally make AMIs public
    if args.make_public:
        print("Making AMIs public")
        make_public(ami_ids, args.region)

    print("Snapshot creation process completed.")
