#!/usr/bin/env python3
"""Mine Claude Code transcripts for recurring user workflows.

Scans every session transcript under ~/.claude/projects/*/ (the local JSONL
logs of all Claude Code conversations), extracts the real user prompts
(filtering out tool results, command stdout, and system reminders), and
reports:
  - per-project prompt/session counts and date range
  - slash-command usage frequency
  - intent clusters (recurring request types) with sample prompts

Use this to spot workflows worth turning into a custom command or skill:
a high-volume intent cluster that isn't already covered by a slash command
is a candidate. Tune INTENT_PATTERNS below to refine the clustering.

Personal clusters go in an optional intent_patterns.local.py next to this
script, defining INTENT_PATTERNS = {name: regex}; its entries are added to
(and can override) the generic ones below.

Run:    python3 mine-transcripts.py
Output: /tmp/transcript_findings.txt (also prints a one-line summary)
"""
import os, json, glob, re, runpy
from collections import Counter, defaultdict

ROOT = os.path.expanduser("~/.claude/projects")
OUT = "/tmp/transcript_findings.txt"
LOCAL_PATTERNS = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "intent_patterns.local.py")

def iter_lines(path):
    with open(path, errors="replace") as fh:
        for line in fh:
            line=line.strip()
            if not line: continue
            try:
                yield json.loads(line)
            except Exception:
                continue

def extract_text(content):
    """Return concatenated text from a message content (str or list of blocks)."""
    if isinstance(content,str):
        return content
    if isinstance(content,list):
        parts=[]
        for b in content:
            if isinstance(b,dict) and b.get("type")=="text":
                parts.append(b.get("text",""))
        return "\n".join(parts)
    return ""

def is_tool_result(content):
    if isinstance(content,list):
        return any(isinstance(b,dict) and b.get("type")=="tool_result" for b in content)
    return False

NOISE_PREFIXES = ("<command-name>","<local-command","Caveat:","[Request interrupted",
                  "<command-message>","<command-args>")

def is_real_prompt(text):
    if not text or not text.strip(): return False
    t=text.strip()
    # skip system reminders / command wrappers / hook noise
    if t.startswith("<system-reminder>"): return False
    if t.startswith(NOISE_PREFIXES): return False
    if t.startswith("<") and ">" in t[:30] and "command" in t[:60].lower(): return False
    return True

prompts=[]            # (project, text)
slash_cmds=Counter()  # slash command usage
proj_prompt_count=Counter()
proj_sessions=Counter()
dates=set()

projects = sorted(glob.glob(os.path.join(ROOT,"*/")))
for pdir in projects:
    proj=os.path.basename(pdir.rstrip("/"))
    files=glob.glob(os.path.join(pdir,"*.jsonl"))
    for f in files:
        proj_sessions[proj]+=1
        for d in iter_lines(f):
            ts=d.get("timestamp","")
            if ts[:10]: dates.add(ts[:10])
            if d.get("type")!="user": continue
            if d.get("isMeta"): continue
            m=d.get("message")
            if not isinstance(m,dict): continue
            c=m.get("content")
            if is_tool_result(c): continue
            text=extract_text(c)
            # detect slash command invocations recorded in command-name wrapper
            cmd_match=re.search(r"<command-name>\s*(/[\w:-]+)", text)
            if cmd_match:
                slash_cmds[cmd_match.group(1)]+=1
            # also raw leading slash typed by user
            if not is_real_prompt(text):
                continue
            stripped=text.strip()
            lead=re.match(r"^(/[\w:-]+)", stripped)
            if lead:
                slash_cmds[lead.group(1)]+=1
            prompts.append((proj,stripped))
            proj_prompt_count[proj]+=1

# Keyword/intent clustering on real prompts
INTENT_PATTERNS = {
    "quiz / test me / interview practice": r"\bquiz\b|test me|interview.*(practice|prep)|drill me|ask me",
    "explain / teach / what is": r"\bexplain\b|what is |what's |teach me|help me understand|walk me through",
    "summarize / distill": r"summari[sz]e|distill|tl;?dr|key takeaway|condense",
    "research / look up / search": r"research|look up|find out|search for|latest on|what.s happening",
    "code / debug / implement": r"\bdebug\b|implement|fix the|error|traceback|write.*(script|function|code)|refactor",
    "draft text (email/message)": r"draft|write.*(email|message|reply|response)|cover letter|linkedin",
    "plan / strategy / decide": r"\bplan\b|strategy|should i|help me decide|pros and cons|tradeoff",
    "review / feedback on": r"review|feedback|critique|look at|check my",
    "memory / remember": r"remember this|save.*memory|memory file|keep track",
}
if os.path.exists(LOCAL_PATTERNS):
    INTENT_PATTERNS.update(runpy.run_path(LOCAL_PATTERNS).get("INTENT_PATTERNS", {}))

intent_counts=Counter()
intent_examples=defaultdict(list)
for proj,p in prompts:
    pl=p.lower()
    for name,pat in INTENT_PATTERNS.items():
        if re.search(pat,pl):
            intent_counts[name]+=1
            if len(intent_examples[name])<4 and 10<len(p)<200:
                intent_examples[name].append(p.replace("\n"," ").strip())

with open(OUT,"w") as o:
    o.write("="*70+"\n")
    o.write("TRANSCRIPT MINING FINDINGS\n")
    o.write("="*70+"\n\n")
    o.write(f"Total real user prompts: {len(prompts)}\n")
    if dates:
        o.write(f"Date range: {min(dates)} -> {max(dates)}  ({len(dates)} distinct days)\n")
    o.write("\nPer-project (sessions / prompts):\n")
    for proj in sorted(proj_sessions, key=lambda x:-proj_prompt_count[x]):
        o.write(f"  {proj_prompt_count[proj]:4d} prompts / {proj_sessions[proj]:2d} sessions  {proj}\n")

    o.write("\n"+"="*70+"\n")
    o.write("SLASH COMMANDS USED (frequency)\n")
    o.write("="*70+"\n")
    for cmd,n in slash_cmds.most_common():
        o.write(f"  {n:4d}  {cmd}\n")

    o.write("\n"+"="*70+"\n")
    o.write("INTENT CLUSTERS (recurring request types, by volume)\n")
    o.write("="*70+"\n")
    for name,n in intent_counts.most_common():
        o.write(f"\n[{n:4d}]  {name}\n")
        for ex in intent_examples[name]:
            o.write(f"        - {ex[:160]}\n")

print("WROTE", OUT)
print(f"prompts={len(prompts)} slash_cmds={sum(slash_cmds.values())}")
