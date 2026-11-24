#!/bin/bash
# Two drafts per achievement, each prompt the shared preamble plus its subject.
cd "$(dirname "$0")"
while IFS='|' read -r name subject; do
  printf '%s\n\n%s\n' "$(cat preamble.txt)" "$subject" > "drafts/$name.txt"
  ~/.claude/skills/gpt-image/generate_image.py --api --file "drafts/$name.txt" -o "drafts/$name.png" -a 1:1 -s 1024x1024 -q high -b opaque -n 2 || echo "FAILED $name"
  sleep 15
done < subjects.txt
