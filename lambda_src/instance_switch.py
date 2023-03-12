import boto3


class TooManyInstancesFoundException(Exception):
    pass


def handler(event, context):
    print(f"Received a power{event['state']} request")
    ec2 = boto3.client("ec2")
    di = ec2.describe_instances(
        Filters=[{'Name': "tag:Name", 'Values': ["*DataSync*"]}])
    instances = di['Reservations'][0]['Instances']

    if len(instances) == 1:
        if event['state'] == "on":
            ec2.start_instances(InstanceIds=[instances[0]['InstanceId']])
        elif event['state'] == "off":
            ec2.stop_instances(InstanceIds=[instances[0]['InstanceId']])
    else:
        instance_ids = [inst['InstanceId'] for inst in instances]
        raise TooManyInstancesFoundException(
            f"Found too many instances: {instance_ids}")
