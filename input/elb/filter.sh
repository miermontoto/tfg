aws logs put-subscription-filter \
    --log-group-name "<log_group>" \
    --filter-name "LambdaFilter" \
    --filter-pattern "" \
    --destination-arn "<arn_lambda>"
