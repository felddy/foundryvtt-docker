#!/usr/bin/env pytest -vs
"""Tests for postfix container."""

from email.message import EmailMessage
from imaplib import IMAP4_SSL
import smtplib

import pytest

MESSAGE = """
This is a test message sent during the unit tests.
"""
DOMAIN = "example.com"
TEST_USER = "mailarchive"
TEST_PW = "foobar"
IMAP_PORT = 1993


@pytest.mark.parametrize("port", [1025, 1587])
def test_sending_mail(port):
    """Send an email message to the server."""
    msg = EmailMessage()
    msg.set_content(MESSAGE)
    msg["Subject"] = f"Test Message on port {port}"
    msg["From"] = f"test@{DOMAIN}"
    msg["To"] = f"mailarchive@{DOMAIN}"
    with smtplib.SMTP("localhost", port=port) as s:
        s.send_message(msg)


def test_imap_login():
    """Test logging in to the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login("mailarchive", "foobar")


def test_imap_messages_exist():
    """Test test existence of our test messages."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(TEST_USER, TEST_PW)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        assert message_count > 0, "Expected message in the inbox"


def test_imap_access():
    """Test receiving message from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(TEST_USER, TEST_PW)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        typ, data = m.search(None, "ALL")
        assert typ == "OK", "Search did not return OK status"
        message_numbers = data[0].split()
        for num in message_numbers:
            typ, data = m.fetch(num, "(RFC822)")
            assert typ == "OK", f"Fetch of message {num} did not return OK status"
            print("-" * 40)
            print(f"Message: {num}")
            print(data[0][1].decode("utf-8"))
            # mark messag as deleted
            typ, data = m.store(num, "+FLAGS", "\\Deleted")
            assert (
                typ == "OK"
            ), f"Storing '\\deleted' flag on message {num} did not return OK status"
        # expunge all deleted messages
        typ, data = m.expunge()
        assert typ == "OK", "Expunge did not return OK status"


def test_imap_delete_all():
    """Test deleting messages from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(TEST_USER, TEST_PW)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        typ, data = m.search(None, "ALL")
        assert typ == "OK", "Search did not return OK status"
        message_numbers = data[0].split()
        for num in message_numbers:
            # mark messag as deleted
            typ, data = m.store(num, "+FLAGS", "\\Deleted")
            assert (
                typ == "OK"
            ), f"Storing '\\deleted' flag on message {num} did not return OK status"
        # expunge all deleted messages
        typ, data = m.expunge()
        assert typ == "OK", "Expunge did not return OK status"


def test_imap_messages_cleared():
    """Test that all messages were expunged."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(TEST_USER, TEST_PW)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        assert message_count == 0, "Expected the inbox to be empty"
