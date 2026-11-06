import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from train_ondevice import TRAIN, drop_empty_assistant_turns


class DropEmptyAssistantTurns(unittest.TestCase):
    def test_removes_only_fully_empty_assistant_turns(self):
        call = {"role": "assistant", "content": None, "tool_calls": [{"id": "c"}]}
        messages = [
            {"role": "user", "content": "q"},
            call,
            {"role": "tool", "content": "{}"},
            {"role": "assistant", "content": None, "tool_calls": []},
            {"role": "assistant", "content": "  "},
            {"role": "assistant", "content": "answer"},
        ]
        result = drop_empty_assistant_turns(messages)
        self.assertEqual([m["role"] for m in result], ["user", "assistant", "tool", "assistant"])
        self.assertIs(result[1], call)

    @unittest.skipUnless(TRAIN.is_file(), "training data not present")
    def test_no_empty_turns_remain_and_final_answers_untouched(self):
        for line in TRAIN.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            item = json.loads(line)
            kept = drop_empty_assistant_turns(item["messages"])
            self.assertEqual(kept[-1], item["messages"][-1])
            for m in kept:
                if m["role"] == "assistant":
                    self.assertTrue((m.get("content") or "").strip() or m.get("tool_calls"))


if __name__ == "__main__":
    unittest.main()
