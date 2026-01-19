# frozen_string_literal: true

require "net/http"

module XmlNodeStream
  # IO-like wrapper for HTTP responses that allows streaming
  class HttpStream
    # Create a new HttpStream.
    #
    # @param uri [URI] the URI to stream from
    def initialize(uri)
      @uri = uri
      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = (uri.scheme == "https")
      @request = Net::HTTP::Get.new(uri.request_uri)
      @buffer = +""
      @eof = false
      @response = nil
      @body_reader = nil
    end

    # Read data from the stream.
    #
    # @param length [Integer, nil] the number of bytes to read, or nil to read all
    # @param outbuf [String, nil] optional output buffer
    # @return [String, nil] the data read, or nil if at EOF
    def read(length = nil, outbuf = nil)
      ensure_response_started

      if length.nil?
        # Read all remaining data
        result = @buffer.dup
        while (chunk = read_chunk)
          result << chunk
        end
        @buffer = +""
        if outbuf
          outbuf.replace(result)
          outbuf
        else
          result
        end
      else
        # Read specific length
        while @buffer.bytesize < length && !@eof
          chunk = read_chunk
          break if chunk.nil?
          @buffer << chunk
        end

        if @buffer.bytesize >= length
          result = @buffer.byteslice(0, length)
          @buffer = @buffer.byteslice(length..-1) || +""
        else
          result = @buffer.dup
          @buffer = +""
        end

        if result.empty? && @eof
          nil
        elsif outbuf
          outbuf.replace(result)
          outbuf
        else
          result
        end
      end
    end

    # Read a line from the stream.
    #
    # @param sep [String, nil] the line separator
    # @param limit [Integer, nil] maximum number of bytes to read
    # @return [String, nil] the line read, or nil if at EOF
    def gets(sep = $/, limit = nil)
      ensure_response_started

      if sep.nil?
        # Read all
        return read
      end

      sep = sep.to_s

      loop do
        if (idx = @buffer.index(sep))
          line = @buffer.slice!(0, idx + sep.length)
          return line
        end

        break if @eof

        chunk = read_chunk
        if chunk.nil?
          break
        end
        @buffer << chunk
      end

      return nil if @buffer.empty?

      line = @buffer
      @buffer = ""
      line
    end

    alias_method :readline, :gets

    # Check if at end of file.
    #
    # @return [Boolean] true if at EOF
    def eof?
      @eof && @buffer.empty?
    end

    # Close the stream.
    #
    # @return [void]
    def close
      @http.finish if @http&.started?
    end

    # Check if the stream is closed.
    #
    # @return [Boolean] true if closed
    def closed?
      @http.nil? || !@http.started?
    end

    # Return self as the IO object for REXML compatibility.
    #
    # @return [HttpStream] self
    def to_io
      self
    end

    private

    def ensure_response_started
      return if @response

      @http.start unless @http.started?
      @response = @http.request(@request)
      @body_reader = @response.read_body
    end

    def read_chunk
      return nil if @eof

      if @body_reader.is_a?(String)
        # Entire body was read at once
        if @body_reader.empty?
          @eof = true
          return nil
        end
        # Simulate chunking for consistency
        chunk = @body_reader.byteslice(0, 8192) || +""
        @body_reader = @body_reader.byteslice(8192..-1) || +""
        @eof = true if @body_reader.empty?
        chunk
      else
        # Should not happen with webmock but handling for real HTTP
        @eof = true
        nil
      end
    end
  end
end
