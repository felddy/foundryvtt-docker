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
ARCHIVE_USER = "mailarchive"
ARCHIVE_PW = "foobar"
TEST_SEND_USER = "testsender1"
TEST_SEND_PW = "lemmy is god"
IMAP_PORT = 1993


@pytest.mark.parametrize("port", [1025, 1587])
@pytest.mark.parametrize("to_user", [ARCHIVE_USER, TEST_SEND_USER])
def test_sending_mail(port, to_user):
    """Send an email message to the server."""
    msg = EmailMessage()
    msg.set_content(MESSAGE)
    msg["Subject"] = f"Test Message on port {port}"
    msg["From"] = f"test@{DOMAIN}"
    msg["To"] = f"{to_user}@{DOMAIN}"
    with smtplib.SMTP("localhost", port=port) as s:
        s.send_message(msg)


@pytest.mark.parametrize(
    "username,password",
    [
        (ARCHIVE_USER, ARCHIVE_PW),
        (TEST_SEND_USER, TEST_SEND_PW),
        pytest.param(ARCHIVE_USER, TEST_SEND_PW, marks=pytest.mark.xfail),
        pytest.param("your_mom", "so_fat", marks=pytest.mark.xfail),
    ],
)
def test_imap_login(username, password):
    """Test logging in to the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_messages_exist(username, password):
    """Test test existence of our test messages."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
        typ, data = m.select()
        assert typ == "OK", f"Select did not return OK status for {username}"
        message_count = int(data[0])
        print(f"{username} inbox message count: {message_count}")
        assert message_count > 0, f"Expected message in the {username} inbox"


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_reading(username, password):
    """Test receiving message from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
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


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_delete_all(username, password):
    """Test deleting messages from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
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


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_messages_cleared(username, password):
    """Test that all messages were expunged."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        assert message_count == 0, "Expected the inbox to be empty"
