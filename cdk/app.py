#!/usr/bin/env python3

# cdk: 1.25.0
from aws_cdk import (
    aws_ec2,
    aws_ecs,
    aws_ecs_patterns,
    aws_servicediscovery,
    aws_iam,
    core,
)

from os import getenv


# Creating a construct that will populate the required objects created in the platform repo such as vpc, ecs cluster, and service discovery namespace
class BasePlatform(core.Construct):
    
    def __init__(self, scope: core.Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)
        self.environment_name = 'ecsworkshop'

        # The base platform stack is where the VPC was created, so all we need is the name to do a lookup and import it into this stack for use
        self.vpc = aws_ec2.Vpc.from_lookup(
            self, "VPC",
            vpc_name='{}-base/BaseVPC'.format(self.environment_name)
        )
        
        self.sd_namespace = aws_servicediscovery.PrivateDnsNamespace.from_private_dns_namespace_attributes(
            self, "SDNamespace",
            namespace_name=core.Fn.import_value('NSNAME'),
            namespace_arn=core.Fn.import_value('NSARN'),
            namespace_id=core.Fn.import_value('NSID')
        )
        
        self.ecs_cluster = aws_ecs.Cluster.from_cluster_attributes(
            self, "ECSCluster",
            cluster_name=core.Fn.import_value('ECSClusterName'),
            security_groups=[],
            vpc=self.vpc,
            default_cloud_map_namespace=self.sd_namespace
        )
        
        self.services_sec_grp = aws_ec2.SecurityGroup.from_security_group_id(
            self, "ServicesSecGrp",
            security_group_id=core.Fn.import_value('ServicesSecGrp')
        )


class FrontendService(core.Stack):
    
    def __init__(self, scope: core.Stack, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        self.base_platform = BasePlatform(self, self.stack_name)

        self.fargate_task_image = aws_ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
            image=aws_ecs.ContainerImage.from_registry("adam9098/ecsdemo-frontend"),
            container_port=3000,
            environment={
                "CRYSTAL_URL": "http://ecsdemo-crystal.service:3000/crystal",
                "NODEJS_URL": "http://ecsdemo-nodejs.service:3000",
                "REGION": getenv('AWS_DEFAULT_REGION')
            },
        )

        self.fargate_load_balanced_service = aws_ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "FrontendFargateLBService",
            service_name='ecsdemo-frontend',
            cluster=self.base_platform.ecs_cluster,
            cpu=256,
            memory_limit_mib=512,
            desired_count=1,
            public_load_balancer=True,
            cloud_map_options=self.base_platform.sd_namespace,
            task_image_options=self.fargate_task_image
        )
        
        self.fargate_load_balanced_service.task_definition.add_to_task_role_policy(
            aws_iam.PolicyStatement(
                actions=['ec2:DescribeSubnets'],
                resources=['*']
            )
        )
        
        self.fargate_load_balanced_service.service.connections.allow_to(
            self.base_platform.services_sec_grp,
            port_range=aws_ec2.Port(protocol=aws_ec2.Protocol.TCP, string_representation="frontendtobackend", from_port=3000, to_port=3000)
        )
        
        # Enable Service Autoscaling
        #self.autoscale = self.fargate_load_balanced_service.service.auto_scale_task_count(
        #    min_capacity=1,
        #    max_capacity=10
        #)
        
        #self.autoscale.scale_on_cpu_utilization(
        #    "CPUAutoscaling",
        #    target_utilization_percent=50,
        #    scale_in_cooldown=core.Duration.seconds(30),
        #    scale_out_cooldown=core.Duration.seconds(30)
        #)


_env = core.Environment(account=getenv('AWS_ACCOUNT_ID'), region=getenv('AWS_DEFAULT_REGION'))
environment = "ecsworkshop"
stack_name = "{}-frontend".format(environment)
app = core.App()
FrontendService(app, stack_name, env=_env)
app.synth()
