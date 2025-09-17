import boto3
import time

def is_image_name_in_destination(image_name, destination_client):
    response = destination_client.describe_images(Filters=[{'Name': 'name', 'Values': [image_name]}])
    return len(response['Images']) > 0

def is_image_available(image_id, destination_client):
    response = destination_client.describe_images(ImageIds=[image_id])
    state = response['Images'][0]['State']
    return state == 'available'
    
def copy_amis(region, source_prefix, destination_region):
    source_client = boto3.client('ec2', region_name=region)
    destination_client = boto3.client('ec2', region_name=destination_region)

    response = source_client.describe_images(Filters=[{'Name': 'name', 'Values': [f'{source_prefix}*']}])
    images = response['Images']

    for image in images:
        image_id = image['ImageId']
        image_name = image['Name']
        if not is_image_name_in_destination(image_name, destination_client):
           response = destination_client.copy_image(
              SourceRegion=region,
              SourceImageId=image_id,
              Name=image['Name'],
              Description=image['Name'],
           )
           print(f"Image {image_id} AKA {image_name} copied to {destination_region} with new AMI ID: {response['ImageId']}")


# User-defined variables
source_region = 'us-east-1'  # Replace with the source region where the AMIs are located
source_prefix = 'AMI-SEC565'  # Replace with the desired prefix for the AMIs to copy
destination_region = input("Enter the destination region: ")  # Prompt the user to enter the destination region

copy_amis(source_region, source_prefix, destination_region)
