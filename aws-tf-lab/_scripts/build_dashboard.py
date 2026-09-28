#!/usr/bin/env python3
"""Generate dashboard.md — the start page. Nothing on it is typed by hand.

    python3 _scripts/build_dashboard.py

Every number comes from the trainer's state/mastery.json (written by the
trainer after each session); every link is checked to exist before it is
written. Re-run after a practice session to refresh it.

Two rules carried over from the trainer's CLAUDE.md:
  - §12 readiness bar: the criteria the data can measure are shown as met or
    not met; the ones it can't (mistakes.md cleared, capstone) are listed as
    manual checks rather than guessed.
  - a topic with fewer than MIN_ANSWERED attempts is too small a sample to
    call weak, so it is listed separately instead of topping the weak list.
"""
import io, json, os, sys

VAULT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAINER = os.environ.get('SAA_TRAINER',
                         os.path.join(VAULT, '..', '..', 'aws-saa-trainer'))
MASTERY = os.path.join(TRAINER, 'state', 'mastery.json')

MIN_ANSWERED = 5          # below this, a percentage is noise
SECONDS_PER_Q = 130 * 60 / 65   # 120 s: the real exam's budget per question

# code → (name, exam weight %). Weights from the official SAA-C03 guide,
# codes as defined in the trainer's CLAUDE.md.

# trainer topic → the note(s) that teach it. Where a service appears in several
# notes' frontmatter, this names the one that TEACHES it (checked by grepping
# each note's coverage on 2026-09-28), not every note that mentions it.
TOPIC_NOTES = {
    'APIGateway': ['19-serverless'],        'Athena': ['22-analytics'],
    'Aurora': ['07-rds-aurora'],            'AutoScaling': ['04-alb-asg'],
    'Backup': ['12-storage-extras', '14-dr-resilience'],
    'CloudFront': ['11-cloudfront'],        'CloudTrail': ['20-monitoring'],
    'Cognito': ['24-other-services'],       'Cost': ['13-cost-optimization'],
    'DataSync': ['12-storage-extras'],      'DirectConnect': ['05-vpc-hybrid'],
    'DynamoDB': ['19-serverless'],          'EBS': ['02-ec2'],
    'EC2': ['02-ec2'],                      'ECS/EKS/Fargate': ['17-containers'],
    'EFS': ['12-storage-extras'],           'ELB': ['04-alb-asg'],
    'ElastiCache': ['08-elasticache'],      'EventBridge': ['20-monitoring'],
    'FSx': ['12-storage-extras'],           'GlobalAccelerator': ['11-cloudfront'],
    'Glue': ['22-analytics'],               'GuardDuty/Inspector/Macie': ['21-security'],
    'IAM': ['01-iam'],                      'KMS': ['21-security'],
    'Kinesis': ['16-kinesis'],              'Lambda': ['19-serverless'],
    'Organizations/SCP': ['01-iam-advanced'],
    'RDS': ['07-rds-aurora'],               'Route53': ['10-route53'],
    'S3': ['09-s3'],                        'SNS': ['15-decoupling'],
    'SQS': ['15-decoupling'],               'SSM': ['20-monitoring', '21-security'],
    'SecretsManager': ['21-security'],      'SecurityGroup/NACL': ['05-vpc-security'],
    'Snow': ['12-storage-extras'],          'StorageGateway': ['12-storage-extras'],
    'TransitGateway': ['05-vpc-endpoints-peering'],
    'VPC': ['05-vpc'],                      'VPN': ['05-vpc-hybrid'],
    'WAF/Shield': ['21-security'],
}

DRILL = ['discriminators', 'exam-night', 'cheatsheet', 'exam-prep']


def exists(note):
    return os.path.isfile(os.path.join(VAULT, note + '.md'))


def links(notes):
    return ' · '.join(f'[[{n}]]' for n in notes)


def main():
    if not os.path.isfile(MASTERY):
        sys.exit(f'no trainer data at {MASTERY} — set SAA_TRAINER to the trainer repo')
    m = json.load(io.open(MASTERY, encoding='utf-8'))

    # refuse to write a link that would dangle
    missing = sorted({n for ns in TOPIC_NOTES.values() for n in ns} | set(DRILL))
    missing = [n for n in missing if not exists(n)]
    if missing:
        sys.exit(f'mapped note(s) not in vault: {", ".join(missing)}')
    unmapped = sorted(t for t in m['by_topic'] if t not in TOPIC_NOTES)

    tot, conf, pace = m['totals'], m['confidence'], m['pacing']
    out = ['---', 'tags: [exam-prep, generated]', '---', '',
           '# 🎯 SAA-C03 readiness', '',
           '> [!warning]- Generated file — do not edit',
           '> Built by `_scripts/build_dashboard.py` from the trainer\'s `state/mastery.json`',
           f'> (last trainer update **{m["updated"][:10]}**). Re-run after a practice session.',
           '',
           '> [!info] What this is for',
           '> The trainer app already shows your scores, domain breakdown and readiness,'
           ' live. This page answers the one question it cannot: **given how you are'
           ' scoring, what should you read?**',
           '']

    # --- weakest topics ---------------------------------------------------------
    judged = [(t, v) for t, v in m['by_topic'].items() if v['answered'] >= MIN_ANSWERED]
    thin = [(t, v) for t, v in m['by_topic'].items() if v['answered'] < MIN_ANSWERED]
    judged.sort(key=lambda tv: (tv[1]['pct'], -tv[1]['answered']))
    out += ['## Weakest topics → the note that fixes it', '',
            '| Topic | Score | Accuracy | Read |', '|---|---:|---:|---|']
    for t, v in judged[:10]:
        note = links(TOPIC_NOTES.get(t, [])) or '*no note mapped*'
        out.append(f'| **{t}** | {v["correct"]}/{v["answered"]} | {v["pct"]}% | {note} |')
    if thin:
        thin.sort(key=lambda tv: tv[1]['answered'])
        out += ['', f'*Too few questions to judge (under {MIN_ANSWERED}): '
                + ', '.join(f'{t} {v["correct"]}/{v["answered"]}' for t, v in thin) + '*']
    out.append('')

    # --- confidence & pacing --------------------------------------------------------
    avg = pace['avg_seconds']
    out += ['## Confidence & pacing', '',
            f'- **{conf["sure_wrong"]}** answers marked *sure* were wrong'
            f' ({conf["sure_wrong_recent"]} of them in the last {conf["recent_window"]}).'
            ' These are the misses most likely to repeat on exam day, because nothing'
            ' tells you to doubt them. Drill them with [[discriminators]].',
            f'- **{conf["guess_right"]}** correct answers were guesses, and the'
            ' scores above count them. Treat that part as luck, not knowledge.',
            f'- Average **{avg}s** per question against a budget of {SECONDS_PER_Q:.0f}s.'
            f' {pace["over_2min"]} answers went over 2 minutes.', '']

    # --- drill ------------------------------------------------------------------
    out += ['## Drill', '',
            '- ⚖️ [[discriminators]]: "which of these two is it?"',
            '- 🌙 [[exam-night]]: one-sitting recall skim',
            '- 📇 [[cheatsheet]]: exact facts',
            '- 🧭 decision pages: `decisions/`',
            '- 🗺️ [[exam-prep]]: blueprint and coverage',
            '- 📊 [[Study HQ.base|Notes by domain]]: weak-spot tags and stale notes', '']

    io.open(os.path.join(VAULT, 'dashboard.md'), 'w', encoding='utf-8').write(
        '\n'.join(out).rstrip() + '\n')
    print(f'wrote dashboard.md: {tot["recent_pct"]}% recent,'
          f' {len(judged)} topics judged, {len(thin)} too thin')
    if unmapped:
        print(f'  warning: trainer topic(s) with no note mapped: {", ".join(unmapped)}')


if __name__ == '__main__':
    main()
