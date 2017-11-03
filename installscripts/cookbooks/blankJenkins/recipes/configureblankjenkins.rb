#
# Cookbook Name:: jenkins
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute 'resizeJenkinsMemorySettings' do
  command "sudo sed -i 's/JENKINS_JAVA_OPTIONS=.*.$/JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=512m\"/' /etc/sysconfig/jenkins"
end

execute 'chmodservices' do
  command "chmod -R 755 ~/cookbooks/jenkins/files;"
end
directory '/var/lib/jenkins/workspace' do
  owner 'jenkins'
  group 'jenkins'
  mode '0777'
  recursive true
  action :create
end
execute 'startjenkins' do 
  command "sudo service jenkins start"
end
execute 'copyJenkinsClientJar' do
  command "cp #{node['client']['jar']} ~/jenkins-cli.jar; chmod 755 ~/jenkins-cli.jar"
end
execute 'createJobExecUser' do
  command "sleep 30;echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount(\"jobexec\", \"jenkinsadmin\")' | java -jar #{node['client']['jar']} -auth @#{node['authfile']} -s http://localhost:8080/ groovy ="
end

execute 'copyXmls' do
  command "tar -xvf ~/cookbooks/jenkins/files/default/xmls.tar"
  cwd "/var/lib/jenkins"
end
execute 'copyConfigXml' do
  command "cp ~/cookbooks/jenkins/files/node/config.xml ."
  cwd "/var/lib/jenkins"
end
execute 'copyCredentialsXml' do
  command "cp ~/cookbooks/jenkins/files/credentials/credentials.xml ."
  cwd "/var/lib/jenkins"
end
# script approvals going in with  xmls.tar will be overwritten
execute 'copyScriptApprovals' do
  command "cp #{node['jenkins']['scriptApprovalfile']} #{node['jenkins']['scriptApprovalfiletarget']}"
end
service "jenkins" do
  supports [:stop, :start, :restart]
  action [:restart]
end


if (File.exist?("~/jazz-core"))
	execute 'downloadgitproj' do
  		command "rm -rf ~/jazz-core"
  		cwd '/home/ec2-user'
	end
end
execute 'downloadgitproj' do
  command "/usr/local/git/bin/git clone -b master https://ustharin:Tmobiledemo1@github.com/tmobile/jazz.git jazz-core"

  cwd '/home/ec2-user'
end

execute 'copylinkdir' do
  command "cp -rf ~/jazz-core/aws-apigateway-importer /var/lib; chmod -R 777 /var/lib/aws-apigateway-importer"
end


execute 'createcredentials-jenkins1' do
  command "sleep 30;~/cookbooks/jenkins/files/credentials/jenkins1.sh localhost "
end
execute 'createcredentials-jobexecutor' do
  command "~/cookbooks/jenkins/files/credentials/jobexec.sh localhost "
end
execute 'createcredentials-aws' do
  command "~/cookbooks/jenkins/files/credentials/aws.sh localhost "
end



execute 'createJob-create-service' do
  command "~/cookbooks/jenkins/files/jobs/job_create-service.sh localhost create-service #{node['bitbucketelb']}"
end
execute 'createJob-delete-service' do
  command "~/cookbooks/jenkins/files/jobs/job_delete-service.sh localhost delete-service #{node['bitbucketelb']}"
end
execute 'createJob-job_build_pack_api' do
  command "~/cookbooks/jenkins/files/jobs/job_build_java_api.sh localhost build_pack_api #{node['bitbucketelb']}"
end
execute 'createJob-bitbucketteam_newService' do
  command "~/cookbooks/jenkins/files/jobs/job_bitbucketteam_newService.sh localhost bitbucketteam_newService #{node['bitbucketelb']}"
end
execute 'job_build-deploy-platform-service' do
  command "~/cookbooks/jenkins/files/jobs/job_build-deploy-platform-service.sh localhost build-deploy-platform-service  #{node['bitbucketelb']}  #{node['region']}"
end
execute 'job_deploy-all-platform-services' do
  command "~/cookbooks/jenkins/files/jobs/job_deploy-all-platform-services.sh localhost deploy-all-platform-services #{node['bitbucketelb']}  #{node['region']}"
end
execute 'createJob-job-pack-lambda' do
  command "~/cookbooks/jenkins/files/jobs/job_build_pack_lambda.sh localhost build-pack-lambda #{node['bitbucketelb']}"
end
execute 'createJob-job-build-pack-website' do
  command "~/cookbooks/jenkins/files/jobs/job_build_pack_website.sh localhost build-pack-website #{node['bitbucketelb']}"
end
link '/usr/bin/aws-api-import' do
  to '~/jazz-core/aws-apigateway-importer/aws-api-import.sh'
  owner 'jenkins'
  group 'jenkins'
  mode '0777'
end
link '/usr/bin/aws' do
  to '/usr/local/bin/aws'
  owner 'root'
  group 'root'
  mode '0777'
end

execute 'configureJenkinsProperites' do
  command "~/cookbooks/jenkins/files/node/configureJenkinsProps.sh localhost "
end

execute 'configJenkinsLocConfigXml' do
  command "~/cookbooks/jenkins/files/node/configJenkinsLocConfigXml.sh  #{node['jenkinselb']} "
end


execute 'copyJenkinsPropertyfile' do
  command "cp #{node['jenkins']['propertyfile']} #{node['jenkins']['propertyfiletarget']};chmod 777  #{node['jenkins']['propertyfiletarget']}"
  cwd '/home/ec2-user'
end
execute 'chownJenkinsfolder' do
  command "chown jenkins:jenkins /var/lib/jenkins"
end

service "jenkins" do
  supports [:stop, :start, :restart]
  action [:restart]
end
execute 'copyJobBuildPackApi' do
  command "sleep 20;~/cookbooks/jenkins/files/jobs/copyJob.sh localhost build_pack_api build_pack_api_dev"
end
execute 'copyJobBuildPackLambda' do
  command "sleep 20;~/cookbooks/jenkins/files/jobs/copyJob.sh localhost build-pack-lambda build-pack-lambda-dev"
end
execute 'copyJobBuildPackLambda' do
  command "sleep 20;~/cookbooks/jenkins/files/jobs/copyJob.sh localhost build-pack-website build-pack-website-dev"
end
