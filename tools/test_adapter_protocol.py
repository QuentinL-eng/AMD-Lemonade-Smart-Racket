import json
import unittest
from serve_adapter import assistant_message

class AdapterProtocol(unittest.TestCase):
    def test_text_and_parallel_native_calls(self):
        self.assertEqual(assistant_message('Estimated result.')['content'],'Estimated result.')
        message=assistant_message('<tool_call>{"name":"get_session_digest","arguments":{}}</tool_call>\n'
            '<tool_call>{"name":"query_shots","arguments":{"type":"forehand"}}</tool_call>')
        calls=message['tool_calls'];self.assertEqual(len(calls),2)
        self.assertNotEqual(calls[0]['id'],calls[1]['id'])
        self.assertEqual(json.loads(calls[1]['function']['arguments']),{'type':'forehand'})

    def test_malformed_and_empty_responses_fail(self):
        for value in ('','<tool_call>{bad}</tool_call>','<tool_call>{"name":"x"}',
                      '<tool_call>{"name":"x","arguments":"{}"}</tool_call>'):
            with self.assertRaises(ValueError):assistant_message(value)

if __name__=='__main__':unittest.main()
