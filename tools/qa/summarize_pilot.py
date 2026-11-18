#!/usr/bin/env python3
"""Aggregate a pilot JSON report. All times come from counted 60 Hz physics frames."""
import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def collect(items, field):
    result = defaultdict(Counter)
    for name, segment in items.items():
        key = segment["kind"] if field == "kind" else name.split(".")[0]
        row = result[key]
        row["segments"] += 1
        for item in ("frames","movement","combat","interaction","waiting","recovery","transition"):
            row[item] += segment.get(item,0)
        for item, count in segment.get("audit",{}).items():
            row[item] += count
    return result


def table(rows, fps):
    print("group        n    total   active    nohit     keys     move    fight      use     wait     stun    outro")
    for name, row in rows.items():
        active = sum(row[x] for x in ("movement","combat","interaction"))
        values = [row["frames"],active,row["active_excluding_hit_stop"],row["keys"],
                  row["movement"],row["combat"],row["interaction"],row["waiting"],
                  row["recovery"],row["transition"]]
        print(f"{name:11} {row['segments']:2d} " + " ".join(f"{v/fps:8.1f}" for v in values))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report",type=Path)
    args=parser.parse_args()
    report=json.loads(args.report.read_text())
    entries={**report["sections"],**report.get("interlude_sections",{})}
    print(f"success={report['success']}, retries={report['retries']}, "
          f"wall={report['wall_seconds']:.3f}, simulated={report['simulated_seconds']:.2f}, "
          f"route={report['route_game_seconds']:.2f}")
    kinds=collect(entries,"kind")
    totals=sum(kinds.values(),Counter())
    table({**kinds,"TOTAL":totals},report["physics_fps"])
    table(collect(entries,"chapter"),report["physics_fps"])
    print("No input during attack windup / follow-through: "
          f"{totals['hands_off_attack_windup']/60:.1f}s / {totals['hands_off_attack_followthrough']/60:.1f}s")
    print("Input-down counts:",report.get("input_counts",{}))
    print("Archives:",len(report.get("archive_tapes",[])))


if __name__=="__main__":
    main()
