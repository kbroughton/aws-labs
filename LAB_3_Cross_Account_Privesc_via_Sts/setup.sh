export AWS_CORE_ACCOUNT=111111111111
export AWS_APP1_ACCOUNT=222222222222
# The app resources are same for all app1,2... they only explicity
# reference the core account and are created with AWS_PROFILE=<account_profile>
# prefixing the terraform apply.
sed "s/000000000000/${AWS_CORE_ACCOUNT}/g" app.tmpl.tf > app1/main.tf
sed "s/000000000000/${AWS_CORE_ACCOUNT}/g" core.tmpl.tf > core/main.tf

