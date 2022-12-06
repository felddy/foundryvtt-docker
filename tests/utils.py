"""Helper utilities for pytest."""

# Standard Python Libraries
from datetime import datetime
from queue import Queue
import threading


class LogTailer(object):
    """Create a separate threat to follow the logs and add to a queue."""

    def __init__(self, container, since: datetime):
        """Initialize the log tailer."""
        self.log_generator = container.logs(
            follow=True,
            since=since,
            stream=True,
        )
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.queue: Queue = Queue()
        self.thread.start()

    def _run(self):
        for line in self.log_generator:
            self.queue.put(line.decode("utf-8"))

    def read(self):
        """Read the next line from the queue if possible."""
        if self.queue.empty():
            return None
        return self.queue.get()

    def empty(self):
        """Return if the queue is empty."""
        return self.queue.empty()


class RedactedPrinter(object):
    """Prints lines to stdout with redactions applied."""

    def __init__(self, redaction_regexes):
        """Initialize the printer."""
        self.redaction_regexes = redaction_regexes

    def print(self, *args, **kwargs):
        """Print with redaction of sensitive information."""
        # Combine all of the arguments into a single string
        text = " ".join(map(str, args))

        # For each regular expression, replace the capture groups with asterisks.
        for regex in self.redaction_regexes:
            text = regex.sub(lambda m: "".join("*" * len(g) for g in m.groups()), text)

        # Print the redacted text to stdout
        print(text, **kwargs)
