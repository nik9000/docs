# frozen_string_literal: true

require 'open3'

##
# Wrapper around a subprocess that serves docs.
class ServingDocs
  ##
  # Reads the logs of the preview without updating them from the subprocess.
  attr_reader :logs

  def initialize(cmd)
    _stdin, @out, @wait_thr = Open3.popen2e(*cmd)
    @logs = ''
  end

  ##
  # Waits for the logs to match a regex. The timeout is in seconds.
  def wait_for_logs(regexp, timeout)
    start = Time.now
    loop do
      return if regexp =~ read_logs
      if Time.now - start > timeout
        raise "Logs didn't match [#{regexp}]:\n#{logs}"
      end

      sleep 0.1
    end
  end

  ##
  # Ask the serving processes politely if they'd please die. Then wait for them
  # to say goodbye.
  def exit
    Process.kill 'TERM', @wait_thr.pid
    @wait_thr.exit
    wait_for_logs(/^Terminated preview services$/, 10)
  end

  private

  ##
  # Reads some logs from the subprocess if there are any ready and returns all
  # logs we've read.
  def read_logs
    @logs += @out.read_nonblock(10_000)
  rescue EOFError
    @logs
  rescue IO::WaitReadable
    # There isn't any data available, just return what we have
    @logs
  end
end
