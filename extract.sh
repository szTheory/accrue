for summary in .planning/phases/14[4-8]-*/*-SUMMARY.md; do
  reqs=$(gsd-sdk query summary-extract "$summary" --fields requirements_completed --pick requirements_completed 2>/dev/null)
  if [ -n "$reqs" ] && [ "$reqs" != "null" ] && [ "$reqs" != "[]" ]; then
    echo "$summary: $reqs"
  fi
done