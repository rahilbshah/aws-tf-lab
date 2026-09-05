###############################################################################
# The SNS topic — the fan-out point
###############################################################################

# TODO(1): aws_sns_topic
#          One publish here becomes one copy per subscriber.
#          Note: a topic with no subscribers silently discards what you
#          publish. Worth knowing before you wonder where your first test
#          message went.
