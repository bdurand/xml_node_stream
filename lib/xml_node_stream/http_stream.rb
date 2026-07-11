# frozen_string_literal: true

require "net/http"

module XmlNodeStream
  # Error raised when an HTTP request returns an unsuccessful response.
  class HttpError < StandardError
    attr_reader :response

    # @param message [String] the error message
    # @param response [Net::HTTPResponse, nil] the HTTP response that caused the error
    def initialize(message, response = nil)
      super(message)
      @response = response
    end
  end

  # IO-like wrapper for HTTP responses that allows streaming
  class HttpStream
    # Default timeout values in seconds
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_READ_TIMEOUT = 60

    # Maximum number of redirects to follow
    MAX_REDIRECTS = 5

    # Create a new HttpStream.
    #
    # @param uri [URI] the URI to stream from
    # @param open_timeout [Integer] connection timeout in seconds (default 10)
    # @param read_timeout [Integer] read timeout in seconds (default 60)
    def initialize(uri, open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT)
      @uri = uri
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @http = nil
      @buffer = +""
      @eof = false
      @response = nil
      @fiber = nil
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
      @buffer = +""
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
    rescue
      # Ignore errors during close to ensure cleanup completes
      nil
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
      return if @fiber

      # The request runs inside a fiber so that the response body can be consumed incrementally.
      # Net::HTTP#request with a block streams the body via read_body; each chunk is yielded out
      # of the fiber and pulled on demand by read_chunk without buffering the whole response.
      @fiber = Fiber.new do
        uri = @uri
        redirects = 0

        loop do
          connect(uri)
          request = Net::HTTP::Get.new(uri.request_uri)
          redirect_location = nil

          @http.request(request) do |response|
            @response = response

            case response
            when Net::HTTPRedirection
              redirects += 1
              if redirects > MAX_REDIRECTS
                raise HttpError.new("Too many redirects requesting #{@uri}", response)
              end
              redirect_location = response["Location"]
              unless redirect_location
                raise HttpError.new("Redirect without Location header from #{uri}", response)
              end
            when Net::HTTPSuccess
              response.read_body do |chunk|
                Fiber.yield(chunk) unless chunk.empty?
              end
            else
              raise HttpError.new("HTTP error #{response.code} requesting #{uri}", response)
            end
          end

          break unless redirect_location

          uri = URI.join(uri.to_s, redirect_location)
        end

        nil
      end
    end

    def connect(uri)
      close

      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = (uri.scheme == "https")
      @http.open_timeout = @open_timeout
      @http.read_timeout = @read_timeout
      @http.start
    end

    def read_chunk
      return nil if @eof

      chunk = (@fiber.alive? ? @fiber.resume : nil)
      @eof = true if chunk.nil?
      chunk
    end
  end
end
