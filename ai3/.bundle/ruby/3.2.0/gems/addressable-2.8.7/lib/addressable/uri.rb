# frozen_string_literal: true

#--
# Copyright (C) Bob Aman
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#++

require 'addressable/version'
require 'addressable/idna'
require 'public_suffix'

##
# Addressable is a library for processing links and URIs.
module Addressable
  ##
  # This is an implementation of a URI parser based on
  # <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>,
  # <a href="http://www.ietf.org/rfc/rfc3987.txt">RFC 3987</a>.
  class URI
    ##
    # Raised if something other than a uri is supplied.
    class InvalidURIError < StandardError
    end

    ##
    # Container for the character classes specified in
    # <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>.
    #
    # Note: Concatenated and interpolated `String`s are not affected by the
    #       `frozen_string_literal` directive and must be frozen explicitly.
    #
    #       Interpolated `String`s *were* frozen this way before Ruby 3.0:
    #       https://bugs.ruby-lang.org/issues/17104
    module CharacterClasses
      ALPHA = 'a-zA-Z'
      DIGIT = '0-9'
      GEN_DELIMS = '\\:\\/\\?\\#\\[\\]\\@'
      SUB_DELIMS = "\\!\\$\\&\\'\\(\\)\\*\\+\\,\\;\\="
      RESERVED = (GEN_DELIMS + SUB_DELIMS).freeze
      UNRESERVED = (ALPHA + DIGIT + '\\-\\.\\_\\~').freeze
      RESERVED_AND_UNRESERVED = RESERVED + UNRESERVED
      PCHAR = (UNRESERVED + SUB_DELIMS + '\\:\\@').freeze
      SCHEME = (ALPHA + DIGIT + '\\-\\+\\.').freeze
      HOST = (UNRESERVED + SUB_DELIMS + '\\[\\:\\]').freeze
      AUTHORITY = (PCHAR + '\\[\\]').freeze
      PATH = (PCHAR + '\\/').freeze
      QUERY = (PCHAR + '\\/\\?').freeze
      FRAGMENT = (PCHAR + '\\/\\?').freeze
    end

    module NormalizeCharacterClasses
      HOST = /[^#{CharacterClasses::HOST}]/
      UNRESERVED = /[^#{CharacterClasses::UNRESERVED}]/
      PCHAR = /[^#{CharacterClasses::PCHAR}]/
      SCHEME = /[^#{CharacterClasses::SCHEME}]/
      FRAGMENT = /[^#{CharacterClasses::FRAGMENT}]/
      QUERY = %r{[^a-zA-Z0-9\-\.\_\~\!\$\'\(\)\*\+\,\=\:\@\/\?%]|%(?!2B|2b)}
    end

    module CharacterClassesRegexps
      AUTHORITY = /[^#{CharacterClasses::AUTHORITY}]/
      FRAGMENT = /[^#{CharacterClasses::FRAGMENT}]/
      HOST = /[^#{CharacterClasses::HOST}]/
      PATH = /[^#{CharacterClasses::PATH}]/
      QUERY = /[^#{CharacterClasses::QUERY}]/
      RESERVED = /[^#{CharacterClasses::RESERVED}]/
      RESERVED_AND_UNRESERVED = /[^#{CharacterClasses::RESERVED_AND_UNRESERVED}]/
      SCHEME = /[^#{CharacterClasses::SCHEME}]/
      UNRESERVED = /[^#{CharacterClasses::UNRESERVED}]/
    end

    SLASH = '/'
    EMPTY_STR = ''

    URIREGEX = %r{^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$}

    PORT_MAPPING = {
      'http' => 80,
      'https' => 443,
      'ftp' => 21,
      'tftp' => 69,
      'sftp' => 22,
      'ssh' => 22,
      'svn+ssh' => 22,
      'telnet' => 23,
      'nntp' => 119,
      'gopher' => 70,
      'wais' => 210,
      'ldap' => 389,
      'prospero' => 1525
    }.freeze

    ##
    # Returns a URI object based on the parsed string.
    #
    # @param [String, Addressable::URI, #to_str] uri
    #   The URI string to parse.
    #   No parsing is performed if the object is already an
    #   <code>Addressable::URI</code>.
    #
    # @return [Addressable::URI] The parsed URI.
    def self.parse(uri)
      # If we were given nil, return nil.
      return nil unless uri
      # If a URI object is passed, just return itself.
      return uri.dup if uri.is_a?(self)

      # If a URI object of the Ruby standard library variety is passed,
      # convert it to a string, then parse the string.
      # We do the check this way because we don't want to accidentally
      # cause a missing constant exception to be thrown.
      uri = uri.to_s if uri.class.name =~ /^URI\b/

      # Otherwise, convert to a String
      unless uri.is_a?(String)
        begin
          uri = uri.to_str
        rescue TypeError, NoMethodError
          raise TypeError, "Can't convert #{uri.class} into String."
        end
      end

      # This Regexp supplied as an example in RFC 3986, and it works great.
      scan = uri.scan(URIREGEX)
      fragments = scan[0]
      scheme = fragments[1]
      authority = fragments[3]
      path = fragments[4]
      query = fragments[6]
      fragment = fragments[8]
      user = nil
      password = nil
      host = nil
      port = nil
      unless authority.nil?
        # The Regexp above doesn't split apart the authority.
        userinfo = authority[/^([^\[\]]*)@/, 1]
        unless userinfo.nil?
          user = userinfo.strip[/^([^:]*):?/, 1]
          password = userinfo.strip[/:(.*)$/, 1]
        end

        host = authority.sub(
          /^([^\[\]]*)@/, EMPTY_STR
        ).sub(
          /:([^:@\[\]]*?)$/, EMPTY_STR
        )

        port = authority[/:([^:@\[\]]*?)$/, 1]
        port = nil if port == EMPTY_STR
      end

      new(
        scheme: scheme,
        user: user,
        password: password,
        host: host,
        port: port,
        path: path,
        query: query,
        fragment: fragment
      )
    end

    ##
    # Converts an input to a URI. The input does not have to be a valid
    # URI — the method will use heuristics to guess what URI was intended.
    # This is not standards-compliant, merely user-friendly.
    #
    # @param [String, Addressable::URI, #to_str] uri
    #   The URI string to parse.
    #   No parsing is performed if the object is already an
    #   <code>Addressable::URI</code>.
    # @param [Hash] hints
    #   A <code>Hash</code> of hints to the heuristic parser.
    #   Defaults to <code>{:scheme => "http"}</code>.
    #
    # @return [Addressable::URI] The parsed URI.
    def self.heuristic_parse(uri, hints = {})
      # If we were given nil, return nil.
      return nil unless uri
      # If a URI object is passed, just return itself.
      return uri.dup if uri.is_a?(self)

      # If a URI object of the Ruby standard library variety is passed,
      # convert it to a string, then parse the string.
      # We do the check this way because we don't want to accidentally
      # cause a missing constant exception to be thrown.
      uri = uri.to_s if uri.class.name =~ /^URI\b/

      raise TypeError, "Can't convert #{uri.class} into String." unless uri.respond_to?(:to_str)

      # Otherwise, convert to a String
      uri = uri.to_str.dup.strip
      hints = {
        scheme: 'http'
      }.merge(hints)
      case uri
      when %r{^http:/}i
        uri.sub!(%r{^http:/+}i, 'http://')
      when %r{^https:/}i
        uri.sub!(%r{^https:/+}i, 'https://')
      when %r{^feed:/+http:/}i
        uri.sub!(%r{^feed:/+http:/+}i, 'feed:http://')
      when %r{^feed:/}i
        uri.sub!(%r{^feed:/+}i, 'feed://')
      when %r[^file:/{4}]i
        uri.sub!(%r{^file:/+}i, 'file:////')
      when %r{^file://localhost/}i
        uri.sub!(%r{^file://localhost/+}i, 'file:///')
      when %r{^file:/+}i
        uri.sub!(%r{^file:/+}i, 'file:///')
      when /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        uri.sub!(/^/, hints[:scheme] + '://')
      when /\A\d+\..*:\d+\z/
        uri = "#{hints[:scheme]}://#{uri}"
      end
      match = uri.match(URIREGEX)
      fragments = match.captures
      authority = fragments[3]
      if authority && authority.length > 0
        new_authority = authority.tr('\\', '/').gsub(' ', '%20')
        # NOTE: We want offset 4, not 3!
        offset = match.offset(4)
        uri = uri.dup
        uri[offset[0]...offset[1]] = new_authority
      end
      parsed = parse(uri)
      parsed = parse(hints[:scheme] + '://' + uri) if parsed.scheme =~ %r{^[^/?#\.]+\.[^/?#]+$}
      if parsed.path.include?('.')
        if parsed.path[/\b@\b/]
          parsed.scheme = 'mailto' unless parsed.scheme
        elsif new_host = parsed.path[%r{^([^/]+\.[^/]*)}, 1]
          parsed.defer_validation do
            new_path = parsed.path.sub(
              Regexp.new('^' + Regexp.escape(new_host)), EMPTY_STR
            )
            parsed.host = new_host
            parsed.path = new_path
            parsed.scheme = hints[:scheme] unless parsed.scheme
          end
        end
      end
      parsed
    end

    ##
    # Converts a path to a file scheme URI. If the path supplied is
    # relative, it will be returned as a relative URI. If the path supplied
    # is actually a non-file URI, it will parse the URI as if it had been
    # parsed with <code>Addressable::URI.parse</code>. Handles all of the
    # various Microsoft-specific formats for specifying paths.
    #
    # @param [String, Addressable::URI, #to_str] path
    #   Typically a <code>String</code> path to a file or directory, but
    #   will return a sensible return value if an absolute URI is supplied
    #   instead.
    #
    # @return [Addressable::URI]
    #   The parsed file scheme URI or the original URI if some other URI
    #   scheme was provided.
    #
    # @example
    #   base = Addressable::URI.convert_path("/absolute/path/")
    #   uri = Addressable::URI.convert_path("relative/path")
    #   (base + uri).to_s
    #   #=> "file:///absolute/path/relative/path"
    #
    #   Addressable::URI.convert_path(
    #     "c:\\windows\\My Documents 100%20\\foo.txt"
    #   ).to_s
    #   #=> "file:///c:/windows/My%20Documents%20100%20/foo.txt"
    #
    #   Addressable::URI.convert_path("http://example.com/").to_s
    #   #=> "http://example.com/"
    def self.convert_path(path)
      # If we were given nil, return nil.
      return nil unless path
      # If a URI object is passed, just return itself.
      return path if path.is_a?(self)
      raise TypeError, "Can't convert #{path.class} into String." unless path.respond_to?(:to_str)

      # Otherwise, convert to a String
      path = path.to_str.strip

      path.sub!(%r{^file:/?/?}, EMPTY_STR) if path =~ %r{^file:/?/?}
      path = SLASH + path if path =~ /^([a-zA-Z])[\|:]/
      uri = parse(path)

      if uri.scheme.nil?
        # Adjust windows-style uris
        uri.path.sub!(%r{^/?([a-zA-Z])[\|:][\\/]}) do
          "/#{::Regexp.last_match(1).downcase}:/"
        end
        uri.path.tr!('\\', SLASH)
        if File.exist?(uri.path) &&
           File.stat(uri.path).directory?
          uri.path.chomp!(SLASH)
          uri.path = uri.path + '/'
        end

        # If the path is absolute, set the scheme and host.
        if uri.path.start_with?(SLASH)
          uri.scheme = 'file'
          uri.host = EMPTY_STR
        end
        uri.normalize!
      end

      uri
    end

    ##
    # Joins several URIs together.
    #
    # @param [String, Addressable::URI, #to_str] *uris
    #   The URIs to join.
    #
    # @return [Addressable::URI] The joined URI.
    #
    # @example
    #   base = "http://example.com/"
    #   uri = Addressable::URI.parse("relative/path")
    #   Addressable::URI.join(base, uri)
    #   #=> #<Addressable::URI:0xcab390 URI:http://example.com/relative/path>
    def self.join(*uris)
      uri_objects = uris.collect do |uri|
        raise TypeError, "Can't convert #{uri.class} into String." unless uri.respond_to?(:to_str)

        uri.is_a?(self) ? uri : parse(uri.to_str)
      end
      result = uri_objects.shift.dup
      uri_objects.each do |uri|
        result.join!(uri)
      end
      result
    end

    ##
    # Tables used to optimize encoding operations in `self.encode_component`
    # and `self.normalize_component`
    SEQUENCE_ENCODING_TABLE = (0..255).map do |byte|
      format('%02x', byte).freeze
    end.freeze

    SEQUENCE_UPCASED_PERCENT_ENCODING_TABLE = (0..255).map do |byte|
      format('%%%02X', byte).freeze
    end.freeze

    ##
    # Percent encodes a URI component.
    #
    # @param [String, #to_str] component The URI component to encode.
    #
    # @param [String, Regexp] character_class
    #   The characters which are not percent encoded. If a <code>String</code>
    #   is passed, the <code>String</code> must be formatted as a regular
    #   expression character class. (Do not include the surrounding square
    #   brackets.)  For example, <code>"b-zB-Z0-9"</code> would cause
    #   everything but the letters 'b' through 'z' and the numbers '0' through
    #  '9' to be percent encoded. If a <code>Regexp</code> is passed, the
    #   value <code>/[^b-zB-Z0-9]/</code> would have the same effect. A set of
    #   useful <code>String</code> values may be found in the
    #   <code>Addressable::URI::CharacterClasses</code> module. The default
    #   value is the reserved plus unreserved character classes specified in
    #   <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>.
    #
    # @param [Regexp] upcase_encoded
    #   A string of characters that may already be percent encoded, and whose
    #   encodings should be upcased. This allows normalization of percent
    #   encodings for characters not included in the
    #   <code>character_class</code>.
    #
    # @return [String] The encoded component.
    #
    # @example
    #   Addressable::URI.encode_component("simple/example", "b-zB-Z0-9")
    #   => "simple%2Fex%61mple"
    #   Addressable::URI.encode_component("simple/example", /[^b-zB-Z0-9]/)
    #   => "simple%2Fex%61mple"
    #   Addressable::URI.encode_component(
    #     "simple/example", Addressable::URI::CharacterClasses::UNRESERVED
    #   )
    #   => "simple%2Fexample"
    def self.encode_component(component, character_class = CharacterClassesRegexps::RESERVED_AND_UNRESERVED,
                              upcase_encoded = '')
      return nil if component.nil?

      unless component.is_a? String
        begin
          component = if component.is_a?(Symbol) ||
                         component.is_a?(Numeric) ||
                         component.is_a?(TrueClass) ||
                         component.is_a?(FalseClass)
                        component.to_s
                      else
                        component.to_str
                      end
        rescue TypeError, NoMethodError
          raise TypeError, "Can't convert #{component.class} into String."
        end
      end

      unless [String, Regexp].include?(character_class.class)
        raise TypeError,
              "Expected String or Regexp, got #{character_class.inspect}"
      end
      character_class = /[^#{character_class}]/ if character_class.is_a?(String)
      # We can't perform regexps on invalid UTF sequences, but
      # here we need to, so switch to ASCII.
      component = component.dup
      component.force_encoding(Encoding::ASCII_8BIT)
      # Avoiding gsub! because there are edge cases with frozen strings
      component = component.gsub(character_class) do |char|
        SEQUENCE_UPCASED_PERCENT_ENCODING_TABLE[char.ord]
      end
      if upcase_encoded.length > 0
        upcase_encoded_chars = upcase_encoded.bytes.map do |byte|
          SEQUENCE_ENCODING_TABLE[byte]
        end
        component = component.gsub(/%(#{upcase_encoded_chars.join('|')})/,
                                   &:upcase)
      end

      component
    end

    class << self
      alias escape_component encode_component
    end

    ##
    # Unencodes any percent encoded characters within a URI component.
    # This method may be used for unencoding either components or full URIs,
    # however, it is recommended to use the <code>unencode_component</code>
    # alias when unencoding components.
    #
    # @param [String, Addressable::URI, #to_str] uri
    #   The URI or component to unencode.
    #
    # @param [Class] return_type
    #   The type of object to return.
    #   This value may only be set to <code>String</code> or
    #   <code>Addressable::URI</code>. All other values are invalid. Defaults
    #   to <code>String</code>.
    #
    # @param [String] leave_encoded
    #   A string of characters to leave encoded. If a percent encoded character
    #   in this list is encountered then it will remain percent encoded.
    #
    # @return [String, Addressable::URI]
    #   The unencoded component or URI.
    #   The return type is determined by the <code>return_type</code>
    #   parameter.
    def self.unencode(uri, return_type = String, leave_encoded = '')
      return nil if uri.nil?

      unless uri.is_a? String
        begin
          uri = uri.to_str
        rescue NoMethodError, TypeError
          raise TypeError, "Can't convert #{uri.class} into String."
        end
      end
      unless [String, ::Addressable::URI].include?(return_type)
        raise TypeError,
              'Expected Class (String or Addressable::URI), ' +
              "got #{return_type.inspect}"
      end

      result = uri.gsub(/%[0-9a-f]{2}/i) do |sequence|
        c = sequence[1..3].to_i(16).chr
        c.force_encoding(sequence.encoding)
        leave_encoded.include?(c) ? sequence : c
      end

      result.force_encoding(Encoding::UTF_8)
      if return_type == String
        result
      elsif return_type == ::Addressable::URI
        ::Addressable::URI.parse(result)
      end
    end

    class << self
      alias unescape unencode
      alias unencode_component unencode
      alias unescape_component unencode
    end

    ##
    # Normalizes the encoding of a URI component.
    #
    # @param [String, #to_str] component The URI component to encode.
    #
    # @param [String, Regexp] character_class
    #   The characters which are not percent encoded. If a <code>String</code>
    #   is passed, the <code>String</code> must be formatted as a regular
    #   expression character class. (Do not include the surrounding square
    #   brackets.)  For example, <code>"b-zB-Z0-9"</code> would cause
    #   everything but the letters 'b' through 'z' and the numbers '0'
    #   through '9' to be percent encoded. If a <code>Regexp</code> is passed,
    #   the value <code>/[^b-zB-Z0-9]/</code> would have the same effect. A
    #   set of useful <code>String</code> values may be found in the
    #   <code>Addressable::URI::CharacterClasses</code> module. The default
    #   value is the reserved plus unreserved character classes specified in
    #   <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>.
    #
    # @param [String] leave_encoded
    #   When <code>character_class</code> is a <code>String</code> then
    #   <code>leave_encoded</code> is a string of characters that should remain
    #   percent encoded while normalizing the component; if they appear percent
    #   encoded in the original component, then they will be upcased ("%2f"
    #   normalized to "%2F") but otherwise left alone.
    #
    # @return [String] The normalized component.
    #
    # @example
    #   Addressable::URI.normalize_component("simpl%65/%65xampl%65", "b-zB-Z")
    #   => "simple%2Fex%61mple"
    #   Addressable::URI.normalize_component(
    #     "simpl%65/%65xampl%65", /[^b-zB-Z]/
    #   )
    #   => "simple%2Fex%61mple"
    #   Addressable::URI.normalize_component(
    #     "simpl%65/%65xampl%65",
    #     Addressable::URI::CharacterClasses::UNRESERVED
    #   )
    #   => "simple%2Fexample"
    #   Addressable::URI.normalize_component(
    #     "one%20two%2fthree%26four",
    #     "0-9a-zA-Z &/",
    #     "/"
    #   )
    #   => "one two%2Fthree&four"
    def self.normalize_component(component, character_class = CharacterClassesRegexps::RESERVED_AND_UNRESERVED,
                                 leave_encoded = '')
      return nil if component.nil?

      unless component.is_a? String
        begin
          component = component.to_str
        rescue NoMethodError, TypeError
          raise TypeError, "Can't convert #{component.class} into String."
        end
      end

      unless [String, Regexp].include?(character_class.class)
        raise TypeError,
              "Expected String or Regexp, got #{character_class.inspect}"
      end
      if character_class.is_a?(String)
        leave_re = if leave_encoded.length > 0
                     character_class = "#{character_class}%" unless character_class.include?('%')

                     bytes = leave_encoded.bytes
                     leave_encoded_pattern = bytes.map { |b| SEQUENCE_ENCODING_TABLE[b] }.join('|')
                     "|%(?!#{leave_encoded_pattern}|#{leave_encoded_pattern.upcase})"
                   end

        character_class = if leave_re
                            /[^#{character_class}]#{leave_re}/
                          else
                            /[^#{character_class}]/
                          end
      end
      # We can't perform regexps on invalid UTF sequences, but
      # here we need to, so switch to ASCII.
      component = component.dup
      component.force_encoding(Encoding::ASCII_8BIT)
      unencoded = unencode_component(component, String, leave_encoded)
      begin
        encoded = encode_component(
          unencoded.unicode_normalize(:nfc),
          character_class,
          leave_encoded
        )
      rescue ArgumentError
        encoded = encode_component(unencoded)
      end
      encoded.force_encoding(Encoding::UTF_8)
      encoded
    end

    ##
    # Percent encodes any special characters in the URI.
    #
    # @param [String, Addressable::URI, #to_str] uri
    #   The URI to encode.
    #
    # @param [Class] return_type
    #   The type of object to return.
    #   This value may only be set to <code>String</code> or
    #   <code>Addressable::URI</code>. All other values are invalid. Defaults
    #   to <code>String</code>.
    #
    # @return [String, Addressable::URI]
    #   The encoded URI.
    #   The return type is determined by the <code>return_type</code>
    #   parameter.
    def self.encode(uri, return_type = String)
      return nil if uri.nil?

      unless uri.is_a? String
        begin
          uri = uri.to_str
        rescue NoMethodError, TypeError
          raise TypeError, "Can't convert #{uri.class} into String."
        end
      end

      unless [String, ::Addressable::URI].include?(return_type)
        raise TypeError,
              'Expected Class (String or Addressable::URI), ' +
              "got #{return_type.inspect}"
      end
      uri_object = uri.is_a?(self) ? uri : parse(uri)
      encoded_uri = Addressable::URI.new(
        scheme: encode_component(uri_object.scheme,
                                 Addressable::URI::CharacterClassesRegexps::SCHEME),
        authority: encode_component(uri_object.authority,
                                    Addressable::URI::CharacterClassesRegexps::AUTHORITY),
        path: encode_component(uri_object.path,
                               Addressable::URI::CharacterClassesRegexps::PATH),
        query: encode_component(uri_object.query,
                                Addressable::URI::CharacterClassesRegexps::QUERY),
        fragment: encode_component(uri_object.fragment,
                                   Addressable::URI::CharacterClassesRegexps::FRAGMENT)
      )
      if return_type == String
        encoded_uri.to_s
      elsif return_type == ::Addressable::URI
        encoded_uri
      end
    end

    class << self
      alias escape encode
    end

    ##
    # Normalizes the encoding of a URI. Characters within a hostname are
    # not percent encoded to allow for internationalized domain names.
    #
    # @param [String, Addressable::URI, #to_str] uri
    #   The URI to encode.
    #
    # @param [Class] return_type
    #   The type of object to return.
    #   This value may only be set to <code>String</code> or
    #   <code>Addressable::URI</code>. All other values are invalid. Defaults
    #   to <code>String</code>.
    #
    # @return [String, Addressable::URI]
    #   The encoded URI.
    #   The return type is determined by the <code>return_type</code>
    #   parameter.
    def self.normalized_encode(uri, return_type = String)
      unless uri.is_a? String
        begin
          uri = uri.to_str
        rescue NoMethodError, TypeError
          raise TypeError, "Can't convert #{uri.class} into String."
        end
      end

      unless [String, ::Addressable::URI].include?(return_type)
        raise TypeError,
              'Expected Class (String or Addressable::URI), ' +
              "got #{return_type.inspect}"
      end
      uri_object = uri.is_a?(self) ? uri : parse(uri)
      components = {
        scheme: unencode_component(uri_object.scheme),
        user: unencode_component(uri_object.user),
        password: unencode_component(uri_object.password),
        host: unencode_component(uri_object.host),
        port: (uri_object.port.nil? ? nil : uri_object.port.to_s),
        path: unencode_component(uri_object.path),
        query: unencode_component(uri_object.query),
        fragment: unencode_component(uri_object.fragment)
      }
      components.each do |key, value|
        next if value.nil?

        begin
          components[key] = value.to_str.unicode_normalize(:nfc)
        rescue ArgumentError
          # Likely a malformed UTF-8 character, skip unicode normalization
          components[key] = value.to_str
        end
      end
      encoded_uri = Addressable::URI.new(
        scheme: encode_component(components[:scheme],
                                 Addressable::URI::CharacterClassesRegexps::SCHEME),
        user: encode_component(components[:user],
                               Addressable::URI::CharacterClassesRegexps::UNRESERVED),
        password: encode_component(components[:password],
                                   Addressable::URI::CharacterClassesRegexps::UNRESERVED),
        host: components[:host],
        port: components[:port],
        path: encode_component(components[:path],
                               Addressable::URI::CharacterClassesRegexps::PATH),
        query: encode_component(components[:query],
                                Addressable::URI::CharacterClassesRegexps::QUERY),
        fragment: encode_component(components[:fragment],
                                   Addressable::URI::CharacterClassesRegexps::FRAGMENT)
      )
      if return_type == String
        encoded_uri.to_s
      elsif return_type == ::Addressable::URI
        encoded_uri
      end
    end

    ##
    # Encodes a set of key/value pairs according to the rules for the
    # <code>application/x-www-form-urlencoded</code> MIME type.
    #
    # @param [#to_hash, #to_ary] form_values
    #   The form values to encode.
    #
    # @param [TrueClass, FalseClass] sort
    #   Sort the key/value pairs prior to encoding.
    #   Defaults to <code>false</code>.
    #
    # @return [String]
    #   The encoded value.
    def self.form_encode(form_values, sort = false)
      if form_values.respond_to?(:to_hash)
        form_values = form_values.to_hash.to_a
      elsif form_values.respond_to?(:to_ary)
        form_values = form_values.to_ary
      else
        raise TypeError, "Can't convert #{form_values.class} into Array."
      end

      form_values = form_values.each_with_object([]) do |(key, value), accu|
        if value.is_a?(Array)
          value.each do |v|
            accu << [key.to_s, v.to_s]
          end
        else
          accu << [key.to_s, value.to_s]
        end
      end

      if sort
        # Useful for OAuth and optimizing caching systems
        form_values = form_values.sort
      end
      escaped_form_values = form_values.map do |(key, value)|
        # Line breaks are CRLF pairs
        [
          encode_component(
            key.gsub(/(\r\n|\n|\r)/, "\r\n"),
            CharacterClassesRegexps::UNRESERVED
          ).gsub('%20', '+'),
          encode_component(
            value.gsub(/(\r\n|\n|\r)/, "\r\n"),
            CharacterClassesRegexps::UNRESERVED
          ).gsub('%20', '+')
        ]
      end
      escaped_form_values.map do |(key, value)|
        "#{key}=#{value}"
      end.join('&')
    end

    ##
    # Decodes a <code>String</code> according to the rules for the
    # <code>application/x-www-form-urlencoded</code> MIME type.
    #
    # @param [String, #to_str] encoded_value
    #   The form values to decode.
    #
    # @return [Array]
    #   The decoded values.
    #   This is not a <code>Hash</code> because of the possibility for
    #   duplicate keys.
    def self.form_unencode(encoded_value)
      raise TypeError, "Can't convert #{encoded_value.class} into String." unless encoded_value.respond_to?(:to_str)

      encoded_value = encoded_value.to_str
      split_values = encoded_value.split('&').map do |pair|
        pair.split('=', 2)
      end
      split_values.map do |(key, value)|
        [
          if key
            unencode_component(
              key.gsub('+', '%20')
            ).gsub(/(\r\n|\n|\r)/, "\n")
          end,
          if value
            unencode_component(
              value.gsub('+', '%20')
            ).gsub(/(\r\n|\n|\r)/, "\n")
          end
        ]
      end
    end

    ##
    # Creates a new uri object from component parts.
    #
    # @option [String, #to_str] scheme The scheme component.
    # @option [String, #to_str] user The user component.
    # @option [String, #to_str] password The password component.
    # @option [String, #to_str] userinfo
    #   The userinfo component. If this is supplied, the user and password
    #   components must be omitted.
    # @option [String, #to_str] host The host component.
    # @option [String, #to_str] port The port component.
    # @option [String, #to_str] authority
    #   The authority component. If this is supplied, the user, password,
    #   userinfo, host, and port components must be omitted.
    # @option [String, #to_str] path The path component.
    # @option [String, #to_str] query The query component.
    # @option [String, #to_str] fragment The fragment component.
    #
    # @return [Addressable::URI] The constructed URI object.
    def initialize(options = {})
      if options.has_key?(:authority) && (options.keys & %i[userinfo user password host port]).any?
        raise ArgumentError,
              'Cannot specify both an authority and any of the components ' +
              'within the authority.'
      end
      if options.has_key?(:userinfo) && (options.keys & %i[user password]).any?
        raise ArgumentError,
              'Cannot specify both a userinfo and either the user or password.'
      end

      reset_ivs

      defer_validation do
        # Bunch of crazy logic required because of the composite components
        # like userinfo and authority.
        self.scheme = options[:scheme] if options[:scheme]
        self.user = options[:user] if options[:user]
        self.password = options[:password] if options[:password]
        self.userinfo = options[:userinfo] if options[:userinfo]
        self.host = options[:host] if options[:host]
        self.port = options[:port] if options[:port]
        self.authority = options[:authority] if options[:authority]
        self.path = options[:path] if options[:path]
        self.query = options[:query] if options[:query]
        self.query_values = options[:query_values] if options[:query_values]
        self.fragment = options[:fragment] if options[:fragment]
      end

      to_s # force path validation
    end

    ##
    # Freeze URI, initializing instance variables.
    #
    # @return [Addressable::URI] The frozen URI object.
    def freeze
      normalized_scheme
      normalized_user
      normalized_password
      normalized_userinfo
      normalized_host
      normalized_port
      normalized_authority
      normalized_site
      normalized_path
      normalized_query
      normalized_fragment
      hash
      super
    end

    ##
    # The scheme component for this URI.
    #
    # @return [String] The scheme component.
    attr_reader :scheme

    ##
    # The scheme component for this URI, normalized.
    #
    # @return [String] The scheme component, normalized.
    def normalized_scheme
      return nil unless scheme

      if @normalized_scheme == NONE
        @normalized_scheme = if scheme =~ /^\s*ssh\+svn\s*$/i
                               'svn+ssh'.dup
                             else
                               Addressable::URI.normalize_component(
                                 scheme.strip.downcase,
                                 Addressable::URI::NormalizeCharacterClasses::SCHEME
                               )
                             end
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_scheme)
      @normalized_scheme
    end

    ##
    # Sets the scheme component for this URI.
    #
    # @param [String, #to_str] new_scheme The new scheme component.
    def scheme=(new_scheme)
      if new_scheme && !new_scheme.respond_to?(:to_str)
        raise TypeError, "Can't convert #{new_scheme.class} into String."
      elsif new_scheme
        new_scheme = new_scheme.to_str
      end
      if new_scheme && new_scheme !~ /\A[a-z][a-z0-9\.\+\-]*\z/i
        raise InvalidURIError, "Invalid scheme format: '#{new_scheme}'"
      end

      @scheme = new_scheme
      @scheme = nil if @scheme.to_s.strip.empty?

      # Reset dependent values
      @normalized_scheme = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The user component for this URI.
    #
    # @return [String] The user component.
    attr_reader :user

    ##
    # The user component for this URI, normalized.
    #
    # @return [String] The user component, normalized.
    def normalized_user
      return nil unless user
      return @normalized_user unless @normalized_user == NONE

      @normalized_user = if normalized_scheme =~ /https?/ && user.strip.empty? &&
                            (!password || password.strip.empty?)
                           nil
                         else
                           Addressable::URI.normalize_component(
                             user.strip,
                             Addressable::URI::NormalizeCharacterClasses::UNRESERVED
                           )
                         end

      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_user)
      @normalized_user
    end

    ##
    # Sets the user component for this URI.
    #
    # @param [String, #to_str] new_user The new user component.
    def user=(new_user)
      raise TypeError, "Can't convert #{new_user.class} into String." if new_user && !new_user.respond_to?(:to_str)

      @user = new_user ? new_user.to_str : nil

      # You can't have a nil user with a non-nil password
      @user = EMPTY_STR if !password.nil? && !user

      # Reset dependent values
      @userinfo = nil
      @normalized_userinfo = NONE
      @authority = nil
      @normalized_user = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The password component for this URI.
    #
    # @return [String] The password component.
    attr_reader :password

    ##
    # The password component for this URI, normalized.
    #
    # @return [String] The password component, normalized.
    def normalized_password
      return nil unless password
      return @normalized_password unless @normalized_password == NONE

      @normalized_password = if normalized_scheme =~ /https?/ && password.strip.empty? &&
                                (!user || user.strip.empty?)
                               nil
                             else
                               Addressable::URI.normalize_component(
                                 password.strip,
                                 Addressable::URI::NormalizeCharacterClasses::UNRESERVED
                               )
                             end

      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_password)
      @normalized_password
    end

    ##
    # Sets the password component for this URI.
    #
    # @param [String, #to_str] new_password The new password component.
    def password=(new_password)
      if new_password && !new_password.respond_to?(:to_str)
        raise TypeError, "Can't convert #{new_password.class} into String."
      end

      @password = new_password ? new_password.to_str : nil

      # You can't have a nil user with a non-nil password
      self.user = EMPTY_STR if !@password.nil? && user.nil?

      # Reset dependent values
      @userinfo = nil
      @normalized_userinfo = NONE
      @authority = nil
      @normalized_password = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The userinfo component for this URI.
    # Combines the user and password components.
    #
    # @return [String] The userinfo component.
    def userinfo
      current_user = user
      current_password = password
      (current_user || current_password) && @userinfo ||= if current_user && current_password
                                                            "#{current_user}:#{current_password}"
                                                          elsif current_user && !current_password
                                                            "#{current_user}"
                                                          end
    end

    ##
    # The userinfo component for this URI, normalized.
    #
    # @return [String] The userinfo component, normalized.
    def normalized_userinfo
      return nil unless userinfo
      return @normalized_userinfo unless @normalized_userinfo == NONE

      @normalized_userinfo = begin
        current_user = normalized_user
        current_password = normalized_password
        if !current_user && !current_password
          nil
        elsif current_user && current_password
          "#{current_user}:#{current_password}"
        elsif current_user && !current_password
          "#{current_user}"
        end
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_userinfo)
      @normalized_userinfo
    end

    ##
    # Sets the userinfo component for this URI.
    #
    # @param [String, #to_str] new_userinfo The new userinfo component.
    def userinfo=(new_userinfo)
      if new_userinfo && !new_userinfo.respond_to?(:to_str)
        raise TypeError, "Can't convert #{new_userinfo.class} into String."
      end

      new_user, new_password = if new_userinfo
                                 [
                                   new_userinfo.to_str.strip[/^(.*):/, 1],
                                   new_userinfo.to_str.strip[/:(.*)$/, 1]
                                 ]
                               else
                                 [nil, nil]
                               end

      # Password assigned first to ensure validity in case of nil
      self.password = new_password
      self.user = new_user

      # Reset dependent values
      @authority = nil
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The host component for this URI.
    #
    # @return [String] The host component.
    attr_reader :host

    ##
    # The host component for this URI, normalized.
    #
    # @return [String] The host component, normalized.
    def normalized_host
      return nil unless host

      @normalized_host ||= if host.strip.empty?
                             EMPTY_STR.dup
                           else
                             result = ::Addressable::IDNA.to_ascii(
                               URI.unencode_component(host.strip.downcase)
                             )
                             if result =~ /[^\.]\.$/
                               # Single trailing dots are unnecessary.
                               result = result[0...-1]
                             end
                             result = Addressable::URI.normalize_component(
                               result,
                               NormalizeCharacterClasses::HOST
                             )
                             result
                           end

      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_host)
      @normalized_host
    end

    ##
    # Sets the host component for this URI.
    #
    # @param [String, #to_str] new_host The new host component.
    def host=(new_host)
      raise TypeError, "Can't convert #{new_host.class} into String." if new_host && !new_host.respond_to?(:to_str)

      @host = new_host ? new_host.to_str : nil

      # Reset dependent values
      @authority = nil
      @normalized_host = nil
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # This method is same as URI::Generic#host except
    # brackets for IPv6 (and 'IPvFuture') addresses are removed.
    #
    # @see Addressable::URI#host
    #
    # @return [String] The hostname for this URI.
    def hostname
      v = host
      /\A\[(.*)\]\z/ =~ v ? ::Regexp.last_match(1) : v
    end

    ##
    # This method is same as URI::Generic#host= except
    # the argument can be a bare IPv6 address (or 'IPvFuture').
    #
    # @see Addressable::URI#host=
    #
    # @param [String, #to_str] new_hostname The new hostname for this URI.
    def hostname=(new_hostname)
      if new_hostname &&
         (new_hostname.respond_to?(:ipv4?) || new_hostname.respond_to?(:ipv6?))
        new_hostname = new_hostname.to_s
      elsif new_hostname && !new_hostname.respond_to?(:to_str)
        raise TypeError, "Can't convert #{new_hostname.class} into String."
      end
      v = new_hostname ? new_hostname.to_str : nil
      v = "[#{v}]" if /\A\[.*\]\z/ !~ v && /:/ =~ v
      self.host = v
    end

    ##
    # Returns the top-level domain for this host.
    #
    # @example
    #   Addressable::URI.parse("http://www.example.co.uk").tld # => "co.uk"
    def tld
      PublicSuffix.parse(host, ignore_private: true).tld
    end

    ##
    # Sets the top-level domain for this URI.
    #
    # @param [String, #to_str] new_tld The new top-level domain.
    def tld=(new_tld)
      replaced_tld = host.sub(/#{tld}\z/, new_tld)
      self.host = PublicSuffix::Domain.new(replaced_tld).to_s
    end

    ##
    # Returns the public suffix domain for this host.
    #
    # @example
    #   Addressable::URI.parse("http://www.example.co.uk").domain # => "example.co.uk"
    def domain
      PublicSuffix.domain(host, ignore_private: true)
    end

    ##
    # The authority component for this URI.
    # Combines the user, password, host, and port components.
    #
    # @return [String] The authority component.
    def authority
      host && @authority ||= begin
        authority = String.new
        authority << "#{userinfo}@" unless userinfo.nil?
        authority << host
        authority << ":#{port}" unless port.nil?
        authority
      end
    end

    ##
    # The authority component for this URI, normalized.
    #
    # @return [String] The authority component, normalized.
    def normalized_authority
      return nil unless authority

      @normalized_authority ||= begin
        authority = String.new
        authority << "#{normalized_userinfo}@" unless normalized_userinfo.nil?
        authority << normalized_host
        authority << ":#{normalized_port}" unless normalized_port.nil?
        authority
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_authority)
      @normalized_authority
    end

    ##
    # Sets the authority component for this URI.
    #
    # @param [String, #to_str] new_authority The new authority component.
    def authority=(new_authority)
      if new_authority
        raise TypeError, "Can't convert #{new_authority.class} into String." unless new_authority.respond_to?(:to_str)

        new_authority = new_authority.to_str
        new_userinfo = new_authority[/^([^\[\]]*)@/, 1]
        if new_userinfo
          new_user = new_userinfo.strip[/^([^:]*):?/, 1]
          new_password = new_userinfo.strip[/:(.*)$/, 1]
        end
        new_host = new_authority.sub(
          /^([^\[\]]*)@/, EMPTY_STR
        ).sub(
          /:([^:@\[\]]*?)$/, EMPTY_STR
        )
        new_port =
          new_authority[/:([^:@\[\]]*?)$/, 1]
      end

      # Password assigned first to ensure validity in case of nil
      self.password = new_password
      self.user = new_user
      self.host = new_host
      self.port = new_port

      # Reset dependent values
      @userinfo = nil
      @normalized_userinfo = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The origin for this URI, serialized to ASCII, as per
    # RFC 6454, section 6.2.
    #
    # @return [String] The serialized origin.
    def origin
      if scheme && authority
        if normalized_port
          "#{normalized_scheme}://#{normalized_host}" +
            ":#{normalized_port}"
        else
          "#{normalized_scheme}://#{normalized_host}"
        end
      else
        'null'
      end
    end

    ##
    # Sets the origin for this URI, serialized to ASCII, as per
    # RFC 6454, section 6.2. This assignment will reset the `userinfo`
    # component.
    #
    # @param [String, #to_str] new_origin The new origin component.
    def origin=(new_origin)
      if new_origin
        raise TypeError, "Can't convert #{new_origin.class} into String." unless new_origin.respond_to?(:to_str)

        new_origin = new_origin.to_str
        new_scheme = new_origin[%r{^([^:/?#]+)://}, 1]
        raise InvalidURIError, 'An origin cannot omit the scheme.' unless new_scheme

        new_host = new_origin[%r{://([^/?#:]+)}, 1]
        raise InvalidURIError, 'An origin cannot omit the host.' unless new_host

        new_port = new_origin[%r{:([^:@\[\]/]*?)$}, 1]
      end

      self.scheme = new_scheme
      self.host = new_host
      self.port = new_port
      self.userinfo = nil

      # Reset dependent values
      @userinfo = nil
      @normalized_userinfo = NONE
      @authority = nil
      @normalized_authority = nil
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    # Returns an array of known ip-based schemes. These schemes typically
    # use a similar URI form:
    # <code>//<user>:<password>@<host>:<port>/<url-path></code>
    def self.ip_based_schemes
      port_mapping.keys
    end

    # Returns a hash of common IP-based schemes and their default port
    # numbers. Adding new schemes to this hash, as necessary, will allow
    # for better URI normalization.
    def self.port_mapping
      PORT_MAPPING
    end

    ##
    # The port component for this URI.
    # This is the port number actually given in the URI. This does not
    # infer port numbers from default values.
    #
    # @return [Integer] The port component.
    attr_reader :port

    ##
    # The port component for this URI, normalized.
    #
    # @return [Integer] The port component, normalized.
    def normalized_port
      return nil unless port
      return @normalized_port unless @normalized_port == NONE

      @normalized_port = if URI.port_mapping[normalized_scheme] == port
                           nil
                         else
                           port
                         end
    end

    ##
    # Sets the port component for this URI.
    #
    # @param [String, Integer, #to_s] new_port The new port component.
    def port=(new_port)
      new_port = Addressable::URI.unencode_component(new_port.to_str) if !new_port.nil? && new_port.respond_to?(:to_str)

      if new_port.respond_to?(:valid_encoding?) && !new_port.valid_encoding?
        raise InvalidURIError, 'Invalid encoding in port'
      end

      if !new_port.nil? && !(new_port.to_s =~ /^\d+$/)
        raise InvalidURIError,
              "Invalid port number: #{new_port.inspect}"
      end

      @port = new_port.to_s.to_i
      @port = nil if @port == 0

      # Reset dependent values
      @authority = nil
      @normalized_port = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The inferred port component for this URI.
    # This method will normalize to the default port for the URI's scheme if
    # the port isn't explicitly specified in the URI.
    #
    # @return [Integer] The inferred port component.
    def inferred_port
      if port.to_i == 0
        default_port
      else
        port.to_i
      end
    end

    ##
    # The default port for this URI's scheme.
    # This method will always returns the default port for the URI's scheme
    # regardless of the presence of an explicit port in the URI.
    #
    # @return [Integer] The default port.
    def default_port
      URI.port_mapping[scheme.strip.downcase] if scheme
    end

    ##
    # The combination of components that represent a site.
    # Combines the scheme, user, password, host, and port components.
    # Primarily useful for HTTP and HTTPS.
    #
    # For example, <code>"http://example.com/path?query"</code> would have a
    # <code>site</code> value of <code>"http://example.com"</code>.
    #
    # @return [String] The components that identify a site.
    def site
      (scheme || authority) && @site ||= begin
        site_string = ''.dup
        site_string << "#{scheme}:" unless scheme.nil?
        site_string << "//#{authority}" unless authority.nil?
        site_string
      end
    end

    ##
    # The normalized combination of components that represent a site.
    # Combines the scheme, user, password, host, and port components.
    # Primarily useful for HTTP and HTTPS.
    #
    # For example, <code>"http://example.com/path?query"</code> would have a
    # <code>site</code> value of <code>"http://example.com"</code>.
    #
    # @return [String] The normalized components that identify a site.
    def normalized_site
      return nil unless site

      @normalized_site ||= begin
        site_string = ''.dup
        site_string << "#{normalized_scheme}:" unless normalized_scheme.nil?
        site_string << "//#{normalized_authority}" unless normalized_authority.nil?
        site_string
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_site)
      @normalized_site
    end

    ##
    # Sets the site value for this URI.
    #
    # @param [String, #to_str] new_site The new site value.
    def site=(new_site)
      if new_site
        raise TypeError, "Can't convert #{new_site.class} into String." unless new_site.respond_to?(:to_str)

        new_site = new_site.to_str
        # These two regular expressions derived from the primary parsing
        # expression
        self.scheme = new_site[%r{^(?:([^:/?#]+):)?(?://(?:[^/?#]*))?$}, 1]
        self.authority = new_site[
          %r{^(?:(?:[^:/?#]+):)?(?://([^/?#]*))?$}, 1
        ]
      else
        self.scheme = nil
        self.authority = nil
      end
    end

    ##
    # The path component for this URI.
    #
    # @return [String] The path component.
    attr_reader :path

    NORMPATH = %r{^(?!/)[^/:]*:.*$}
    ##
    # The path component for this URI, normalized.
    #
    # @return [String] The path component, normalized.
    def normalized_path
      @normalized_path ||= begin
        path = self.path.to_s
        if scheme.nil? && path =~ NORMPATH
          # Relative paths with colons in the first segment are ambiguous.
          path = path.sub(':', '%2F')
        end
        # String#split(delimiter, -1) uses the more strict splitting behavior
        # found by default in Python.
        result = path.strip.split(SLASH, -1).map do |segment|
          Addressable::URI.normalize_component(
            segment,
            Addressable::URI::NormalizeCharacterClasses::PCHAR
          )
        end.join(SLASH)

        result = URI.normalize_path(result)
        if result.empty? &&
           %w[http https ftp tftp].include?(normalized_scheme)
          result = SLASH.dup
        end
        result
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_path)
      @normalized_path
    end

    ##
    # Sets the path component for this URI.
    #
    # @param [String, #to_str] new_path The new path component.
    def path=(new_path)
      raise TypeError, "Can't convert #{new_path.class} into String." if new_path && !new_path.respond_to?(:to_str)

      @path = (new_path || EMPTY_STR).to_str
      @path = "/#{@path}" if !@path.empty? && @path[0..0] != SLASH && !host.nil?

      # Reset dependent values
      @normalized_path = nil
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # The basename, if any, of the file in the path component.
    #
    # @return [String] The path's basename.
    def basename
      # Path cannot be nil
      File.basename(path).sub(%r{;[^/]*$}, EMPTY_STR)
    end

    ##
    # The extname, if any, of the file in the path component.
    # Empty string if there is no extension.
    #
    # @return [String] The path's extname.
    def extname
      return nil unless path

      File.extname(basename)
    end

    ##
    # The query component for this URI.
    #
    # @return [String] The query component.
    attr_reader :query

    ##
    # The query component for this URI, normalized.
    #
    # @return [String] The query component, normalized.
    def normalized_query(*flags)
      return nil unless query
      return @normalized_query unless @normalized_query == NONE

      @normalized_query = begin
        modified_query_class = Addressable::URI::CharacterClasses::QUERY.dup
        # Make sure possible key-value pair delimiters are escaped.
        modified_query_class.sub!('\\&', '').sub!('\\;', '')
        pairs = (query || '').split('&', -1)
        pairs.delete_if(&:empty?).uniq! if flags.include?(:compacted)
        pairs.sort! if flags.include?(:sorted)
        component = pairs.map do |pair|
          Addressable::URI.normalize_component(
            pair,
            Addressable::URI::NormalizeCharacterClasses::QUERY,
            '+'
          )
        end.join('&')
        component == '' ? nil : component
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_query)
      @normalized_query
    end

    ##
    # Sets the query component for this URI.
    #
    # @param [String, #to_str] new_query The new query component.
    def query=(new_query)
      raise TypeError, "Can't convert #{new_query.class} into String." if new_query && !new_query.respond_to?(:to_str)

      @query = new_query ? new_query.to_str : nil

      # Reset dependent values
      @normalized_query = NONE
      remove_composite_values
    end

    ##
    # Converts the query component to a Hash value.
    #
    # @param [Class] return_type The return type desired. Value must be either
    #   `Hash` or `Array`.
    #
    # @return [Hash, Array, nil] The query string parsed as a Hash or Array
    #   or nil if the query string is blank.
    #
    # @example
    #   Addressable::URI.parse("?one=1&two=2&three=3").query_values
    #   #=> {"one" => "1", "two" => "2", "three" => "3"}
    #   Addressable::URI.parse("?one=two&one=three").query_values(Array)
    #   #=> [["one", "two"], ["one", "three"]]
    #   Addressable::URI.parse("?one=two&one=three").query_values(Hash)
    #   #=> {"one" => "three"}
    #   Addressable::URI.parse("?").query_values
    #   #=> {}
    #   Addressable::URI.parse("").query_values
    #   #=> nil
    def query_values(return_type = Hash)
      empty_accumulator = Array == return_type ? [] : {}
      raise ArgumentError, 'Invalid return type. Must be Hash or Array.' if return_type != Hash && return_type != Array
      return nil if query.nil?

      split_query = query.split('&').map do |pair|
        pair.split('=', 2) if pair && !pair.empty?
      end.compact
      split_query.each_with_object(empty_accumulator.dup) do |pair, accu|
        # I'd rather use key/value identifiers instead of array lookups,
        # but in this case I really want to maintain the exact pair structure,
        # so it's best to make all changes in-place.
        pair[0] = URI.unencode_component(pair[0])
        if pair[1].respond_to?(:to_str)
          value = pair[1].to_str
          # I loathe the fact that I have to do this. Stupid HTML 4.01.
          # Treating '+' as a space was just an unbelievably bad idea.
          # There was nothing wrong with '%20'!
          # If it ain't broke, don't fix it!
          value = value.tr('+', ' ') if ['http', 'https', nil].include?(scheme)
          pair[1] = URI.unencode_component(value)
        end
        if return_type == Hash
          accu[pair[0]] = pair[1]
        else
          accu << pair
        end
      end
    end

    ##
    # Sets the query component for this URI from a Hash object.
    # An empty Hash or Array will result in an empty query string.
    #
    # @param [Hash, #to_hash, Array] new_query_values The new query values.
    #
    # @example
    #   uri.query_values = {:a => "a", :b => ["c", "d", "e"]}
    #   uri.query
    #   # => "a=a&b=c&b=d&b=e"
    #   uri.query_values = [['a', 'a'], ['b', 'c'], ['b', 'd'], ['b', 'e']]
    #   uri.query
    #   # => "a=a&b=c&b=d&b=e"
    #   uri.query_values = [['a', 'a'], ['b', ['c', 'd', 'e']]]
    #   uri.query
    #   # => "a=a&b=c&b=d&b=e"
    #   uri.query_values = [['flag'], ['key', 'value']]
    #   uri.query
    #   # => "flag&key=value"
    def query_values=(new_query_values)
      if new_query_values.nil?
        self.query = nil
        return nil
      end

      unless new_query_values.is_a?(Array)
        unless new_query_values.respond_to?(:to_hash)
          raise TypeError,
                "Can't convert #{new_query_values.class} into Hash."
        end
        new_query_values = new_query_values.to_hash
        new_query_values = new_query_values.map do |key, value|
          key = key.to_s if key.is_a?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        new_query_values.sort!
      end

      # new_query_values have form [['key1', 'value1'], ['key2', 'value2']]
      buffer = ''.dup
      new_query_values.each do |key, value|
        encoded_key = URI.encode_component(
          key, CharacterClassesRegexps::UNRESERVED
        )
        if value.nil?
          buffer << "#{encoded_key}&"
        elsif value.is_a?(Array)
          value.each do |sub_value|
            encoded_value = URI.encode_component(
              sub_value, CharacterClassesRegexps::UNRESERVED
            )
            buffer << "#{encoded_key}=#{encoded_value}&"
          end
        else
          encoded_value = URI.encode_component(
            value, CharacterClassesRegexps::UNRESERVED
          )
          buffer << "#{encoded_key}=#{encoded_value}&"
        end
      end
      self.query = buffer.chop
    end

    ##
    # The HTTP request URI for this URI.  This is the path and the
    # query string.
    #
    # @return [String] The request URI required for an HTTP request.
    def request_uri
      return nil if absolute? && scheme !~ /^https?$/i

      (
        (path.empty? ? SLASH : path) +
        (query ? "?#{query}" : EMPTY_STR)
      )
    end

    ##
    # Sets the HTTP request URI for this URI.
    #
    # @param [String, #to_str] new_request_uri The new HTTP request URI.
    def request_uri=(new_request_uri)
      raise TypeError, "Can't convert #{new_request_uri.class} into String." unless new_request_uri.respond_to?(:to_str)

      if absolute? && scheme !~ /^https?$/i
        raise InvalidURIError,
              'Cannot set an HTTP request URI for a non-HTTP URI.'
      end
      new_request_uri = new_request_uri.to_str
      path_component = new_request_uri[/^([^\?]*)\??(?:.*)$/, 1]
      query_component = new_request_uri[/^(?:[^\?]*)\?(.*)$/, 1]
      path_component = path_component.to_s
      path_component = (path_component.empty? ? SLASH : path_component)
      self.path = path_component
      self.query = query_component

      # Reset dependent values
      remove_composite_values
    end

    ##
    # The fragment component for this URI.
    #
    # @return [String] The fragment component.
    attr_reader :fragment

    ##
    # The fragment component for this URI, normalized.
    #
    # @return [String] The fragment component, normalized.
    def normalized_fragment
      return nil unless fragment
      return @normalized_fragment unless @normalized_fragment == NONE

      @normalized_fragment = begin
        component = Addressable::URI.normalize_component(
          fragment,
          Addressable::URI::NormalizeCharacterClasses::FRAGMENT
        )
        component == '' ? nil : component
      end
      # All normalized values should be UTF-8
      force_utf8_encoding_if_needed(@normalized_fragment)
      @normalized_fragment
    end

    ##
    # Sets the fragment component for this URI.
    #
    # @param [String, #to_str] new_fragment The new fragment component.
    def fragment=(new_fragment)
      if new_fragment && !new_fragment.respond_to?(:to_str)
        raise TypeError, "Can't convert #{new_fragment.class} into String."
      end

      @fragment = new_fragment ? new_fragment.to_str : nil

      # Reset dependent values
      @normalized_fragment = NONE
      remove_composite_values

      # Ensure we haven't created an invalid URI
      validate
    end

    ##
    # Determines if the scheme indicates an IP-based protocol.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the scheme indicates an IP-based protocol.
    #   <code>false</code> otherwise.
    def ip_based?
      if scheme
        return URI.ip_based_schemes.include?(
          scheme.strip.downcase
        )
      end
      false
    end

    ##
    # Determines if the URI is relative.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the URI is relative. <code>false</code>
    #   otherwise.
    def relative?
      scheme.nil?
    end

    ##
    # Determines if the URI is absolute.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the URI is absolute. <code>false</code>
    #   otherwise.
    def absolute?
      !relative?
    end

    ##
    # Joins two URIs together.
    #
    # @param [String, Addressable::URI, #to_str] The URI to join with.
    #
    # @return [Addressable::URI] The joined URI.
    def join(uri)
      raise TypeError, "Can't convert #{uri.class} into String." unless uri.respond_to?(:to_str)

      unless uri.is_a?(URI)
        # Otherwise, convert to a String, then parse.
        uri = URI.parse(uri.to_str)
      end
      return dup if uri.to_s.empty?

      joined_scheme = nil
      joined_user = nil
      joined_password = nil
      joined_host = nil
      joined_port = nil
      joined_path = nil
      joined_query = nil

      # Section 5.2.2 of RFC 3986
      if uri.scheme.nil?
        if uri.authority.nil?
          if uri.path.nil? || uri.path.empty?
            joined_path = path
            joined_query = if uri.query.nil?
                             query
                           else
                             uri.query
                           end
          else
            if uri.path[0..0] == SLASH
              joined_path = URI.normalize_path(uri.path)
            else
              base_path = path.dup
              base_path = EMPTY_STR if base_path.nil?
              base_path = URI.normalize_path(base_path)

              # Section 5.2.3 of RFC 3986
              #
              # Removes the right-most path segment from the base path.
              if base_path.include?(SLASH)
                base_path.sub!(%r{/[^/]+$}, SLASH)
              else
                base_path = EMPTY_STR
              end

              # If the base path is empty and an authority segment has been
              # defined, use a base path of SLASH
              base_path = SLASH if base_path.empty? && !authority.nil?

              joined_path = URI.normalize_path(base_path + uri.path)
            end
            joined_query = uri.query
          end
          joined_user = user
          joined_password = password
          joined_host = host
          joined_port = port
        else
          joined_user = uri.user
          joined_password = uri.password
          joined_host = uri.host
          joined_port = uri.port
          joined_path = URI.normalize_path(uri.path)
          joined_query = uri.query
        end
        joined_scheme = scheme
      else
        joined_scheme = uri.scheme
        joined_user = uri.user
        joined_password = uri.password
        joined_host = uri.host
        joined_port = uri.port
        joined_path = URI.normalize_path(uri.path)
        joined_query = uri.query
      end
      joined_fragment = uri.fragment

      self.class.new(
        scheme: joined_scheme,
        user: joined_user,
        password: joined_password,
        host: joined_host,
        port: joined_port,
        path: joined_path,
        query: joined_query,
        fragment: joined_fragment
      )
    end
    alias + join

    ##
    # Destructive form of <code>join</code>.
    #
    # @param [String, Addressable::URI, #to_str] The URI to join with.
    #
    # @return [Addressable::URI] The joined URI.
    #
    # @see Addressable::URI#join
    def join!(uri)
      replace_self(join(uri))
    end

    ##
    # Merges a URI with a <code>Hash</code> of components.
    # This method has different behavior from <code>join</code>. Any
    # components present in the <code>hash</code> parameter will override the
    # original components. The path component is not treated specially.
    #
    # @param [Hash, Addressable::URI, #to_hash] The components to merge with.
    #
    # @return [Addressable::URI] The merged URI.
    #
    # @see Hash#merge
    def merge(hash)
      raise TypeError, "Can't convert #{hash.class} into Hash." unless hash.respond_to?(:to_hash)

      hash = hash.to_hash

      if hash.has_key?(:authority) && (hash.keys & %i[userinfo user password host port]).any?
        raise ArgumentError,
              'Cannot specify both an authority and any of the components ' +
              'within the authority.'
      end
      if hash.has_key?(:userinfo) && (hash.keys & %i[user password]).any?
        raise ArgumentError,
              'Cannot specify both a userinfo and either the user or password.'
      end

      uri = self.class.new
      uri.defer_validation do
        # Bunch of crazy logic required because of the composite components
        # like userinfo and authority.
        uri.scheme =
          hash.has_key?(:scheme) ? hash[:scheme] : scheme
        if hash.has_key?(:authority)
          uri.authority =
            hash.has_key?(:authority) ? hash[:authority] : authority
        end
        if hash.has_key?(:userinfo)
          uri.userinfo =
            hash.has_key?(:userinfo) ? hash[:userinfo] : userinfo
        end
        if !hash.has_key?(:userinfo) && !hash.has_key?(:authority)
          uri.user =
            hash.has_key?(:user) ? hash[:user] : user
          uri.password =
            hash.has_key?(:password) ? hash[:password] : password
        end
        unless hash.has_key?(:authority)
          uri.host =
            hash.has_key?(:host) ? hash[:host] : host
          uri.port =
            hash.has_key?(:port) ? hash[:port] : port
        end
        uri.path =
          hash.has_key?(:path) ? hash[:path] : path
        uri.query =
          hash.has_key?(:query) ? hash[:query] : query
        uri.fragment =
          hash.has_key?(:fragment) ? hash[:fragment] : fragment
      end

      uri
    end

    ##
    # Destructive form of <code>merge</code>.
    #
    # @param [Hash, Addressable::URI, #to_hash] The components to merge with.
    #
    # @return [Addressable::URI] The merged URI.
    #
    # @see Addressable::URI#merge
    def merge!(uri)
      replace_self(merge(uri))
    end

    ##
    # Returns the shortest normalized relative form of this URI that uses the
    # supplied URI as a base for resolution. Returns an absolute URI if
    # necessary. This is effectively the opposite of <code>route_to</code>.
    #
    # @param [String, Addressable::URI, #to_str] uri The URI to route from.
    #
    # @return [Addressable::URI]
    #   The normalized relative URI that is equivalent to the original URI.
    def route_from(uri)
      uri = URI.parse(uri).normalize
      normalized_self = normalize
      raise ArgumentError, "Expected absolute URI, got: #{self}" if normalized_self.relative?
      raise ArgumentError, "Expected absolute URI, got: #{uri}" if uri.relative?
      return Addressable::URI.parse("##{normalized_self.fragment}") if normalized_self == uri

      components = normalized_self.to_hash
      if normalized_self.scheme == uri.scheme
        components[:scheme] = nil
        if normalized_self.authority == uri.authority
          components[:user] = nil
          components[:password] = nil
          components[:host] = nil
          components[:port] = nil
          if normalized_self.path == uri.path
            components[:path] = nil
            components[:query] = nil if normalized_self.query == uri.query
          elsif uri.path != SLASH and components[:path]
            self_splitted_path = split_path(components[:path])
            uri_splitted_path = split_path(uri.path)
            self_dir = self_splitted_path.shift
            uri_dir = uri_splitted_path.shift
            while !self_splitted_path.empty? && !uri_splitted_path.empty? and self_dir == uri_dir
              self_dir = self_splitted_path.shift
              uri_dir = uri_splitted_path.shift
            end
            components[:path] = (uri_splitted_path.fill('..') + [self_dir] + self_splitted_path).join(SLASH)
          end
        end
      end
      # Avoid network-path references.
      components[:scheme] = normalized_self.scheme unless components[:host].nil?
      Addressable::URI.new(
        scheme: components[:scheme],
        user: components[:user],
        password: components[:password],
        host: components[:host],
        port: components[:port],
        path: components[:path],
        query: components[:query],
        fragment: components[:fragment]
      )
    end

    ##
    # Returns the shortest normalized relative form of the supplied URI that
    # uses this URI as a base for resolution. Returns an absolute URI if
    # necessary. This is effectively the opposite of <code>route_from</code>.
    #
    # @param [String, Addressable::URI, #to_str] uri The URI to route to.
    #
    # @return [Addressable::URI]
    #   The normalized relative URI that is equivalent to the supplied URI.
    def route_to(uri)
      URI.parse(uri).route_from(self)
    end

    ##
    # Returns a normalized URI object.
    #
    # NOTE: This method does not attempt to fully conform to specifications.
    # It exists largely to correct other people's failures to read the
    # specifications, and also to deal with caching issues since several
    # different URIs may represent the same resource and should not be
    # cached multiple times.
    #
    # @return [Addressable::URI] The normalized URI.
    def normalize
      # This is a special exception for the frequently misused feed
      # URI scheme.
      if (normalized_scheme == 'feed') && (to_s =~ %r{^feed:/*http:/*})
        return URI.parse(
          to_s[%r{^feed:/*(http:/*.*)}, 1]
        ).normalize
      end

      self.class.new(
        scheme: normalized_scheme,
        authority: normalized_authority,
        path: normalized_path,
        query: normalized_query,
        fragment: normalized_fragment
      )
    end

    ##
    # Destructively normalizes this URI object.
    #
    # @return [Addressable::URI] The normalized URI.
    #
    # @see Addressable::URI#normalize
    def normalize!
      replace_self(normalize)
    end

    ##
    # Creates a URI suitable for display to users. If semantic attacks are
    # likely, the application should try to detect these and warn the user.
    # See <a href="http://www.ietf.org/rfc/rfc3986.txt">RFC 3986</a>,
    # section 7.6 for more information.
    #
    # @return [Addressable::URI] A URI suitable for display purposes.
    def display_uri
      display_uri = normalize
      display_uri.host = ::Addressable::IDNA.to_unicode(display_uri.host)
      display_uri
    end

    ##
    # Returns <code>true</code> if the URI objects are equal. This method
    # normalizes both URIs before doing the comparison, and allows comparison
    # against <code>Strings</code>.
    #
    # @param [Object] uri The URI to compare.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the URIs are equivalent, <code>false</code>
    #   otherwise.
    def ===(uri)
      if uri.respond_to?(:normalize)
        uri_string = uri.normalize.to_s
      else
        begin
          uri_string = ::Addressable::URI.parse(uri).normalize.to_s
        rescue InvalidURIError, TypeError
          return false
        end
      end
      normalize.to_s == uri_string
    end

    ##
    # Returns <code>true</code> if the URI objects are equal. This method
    # normalizes both URIs before doing the comparison.
    #
    # @param [Object] uri The URI to compare.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the URIs are equivalent, <code>false</code>
    #   otherwise.
    def ==(other)
      return false unless other.is_a?(URI)

      normalize.to_s == other.normalize.to_s
    end

    ##
    # Returns <code>true</code> if the URI objects are equal. This method
    # does NOT normalize either URI before doing the comparison.
    #
    # @param [Object] uri The URI to compare.
    #
    # @return [TrueClass, FalseClass]
    #   <code>true</code> if the URIs are equivalent, <code>false</code>
    #   otherwise.
    def eql?(other)
      return false unless other.is_a?(URI)

      to_s == other.to_s
    end

    ##
    # A hash value that will make a URI equivalent to its normalized
    # form.
    #
    # @return [Integer] A hash of the URI.
    def hash
      @hash ||= to_s.hash * -1
    end

    ##
    # Clones the URI object.
    #
    # @return [Addressable::URI] The cloned URI.
    def dup
      self.class.new(
        scheme: scheme ? scheme.dup : nil,
        user: user ? user.dup : nil,
        password: password ? password.dup : nil,
        host: host ? host.dup : nil,
        port: port,
        path: path ? path.dup : nil,
        query: query ? query.dup : nil,
        fragment: fragment ? fragment.dup : nil
      )
    end

    ##
    # Omits components from a URI.
    #
    # @param [Symbol] *components The components to be omitted.
    #
    # @return [Addressable::URI] The URI with components omitted.
    #
    # @example
    #   uri = Addressable::URI.parse("http://example.com/path?query")
    #   #=> #<Addressable::URI:0xcc5e7a URI:http://example.com/path?query>
    #   uri.omit(:scheme, :authority)
    #   #=> #<Addressable::URI:0xcc4d86 URI:/path?query>
    def omit(*components)
      invalid_components = components - %i[
        scheme user password userinfo host port authority
        path query fragment
      ]
      unless invalid_components.empty?
        raise ArgumentError,
              "Invalid component names: #{invalid_components.inspect}."
      end
      duplicated_uri = dup
      duplicated_uri.defer_validation do
        components.each do |component|
          duplicated_uri.send((component.to_s + '=').to_sym, nil)
        end
        duplicated_uri.user = duplicated_uri.normalized_user
      end
      duplicated_uri
    end

    ##
    # Destructive form of omit.
    #
    # @param [Symbol] *components The components to be omitted.
    #
    # @return [Addressable::URI] The URI with components omitted.
    #
    # @see Addressable::URI#omit
    def omit!(*components)
      replace_self(omit(*components))
    end

    ##
    # Determines if the URI is an empty string.
    #
    # @return [TrueClass, FalseClass]
    #   Returns <code>true</code> if empty, <code>false</code> otherwise.
    def empty?
      to_s.empty?
    end

    ##
    # Converts the URI to a <code>String</code>.
    #
    # @return [String] The URI's <code>String</code> representation.
    def to_s
      if scheme.nil? && !path.nil? && !path.empty? &&
         path =~ NORMPATH
        raise InvalidURIError,
              "Cannot assemble URI string with ambiguous path: '#{path}'"
      end
      @uri_string ||= begin
        uri_string = String.new
        uri_string << "#{scheme}:" unless scheme.nil?
        uri_string << "//#{authority}" unless authority.nil?
        uri_string << path.to_s
        uri_string << "?#{query}" unless query.nil?
        uri_string << "##{fragment}" unless fragment.nil?
        uri_string.force_encoding(Encoding::UTF_8)
        uri_string
      end
    end

    ##
    # URI's are glorified <code>Strings</code>. Allow implicit conversion.
    alias to_str to_s

    ##
    # Returns a Hash of the URI components.
    #
    # @return [Hash] The URI as a <code>Hash</code> of components.
    def to_hash
      {
        scheme: scheme,
        user: user,
        password: password,
        host: host,
        port: port,
        path: path,
        query: query,
        fragment: fragment
      }
    end

    ##
    # Returns a <code>String</code> representation of the URI object's state.
    #
    # @return [String] The URI object's state, as a <code>String</code>.
    def inspect
      format('#<%s:%#0x URI:%s>', URI.to_s, object_id, to_s)
    end

    ##
    # This method allows you to make several changes to a URI simultaneously,
    # which separately would cause validation errors, but in conjunction,
    # are valid.  The URI will be revalidated as soon as the entire block has
    # been executed.
    #
    # @param [Proc] block
    #   A set of operations to perform on a given URI.
    def defer_validation
      raise LocalJumpError, 'No block given.' unless block_given?

      @validation_deferred = true
      yield
      @validation_deferred = false
      validate
    ensure
      @validation_deferred = false
    end

    def encode_with(coder)
      instance_variables.each do |ivar|
        value = instance_variable_get(ivar)
        if value != NONE
          key = ivar.to_s.slice(1..-1)
          coder[key] = value
        end
      end
      nil
    end

    def init_with(coder)
      reset_ivs
      coder.map.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      nil
    end

    protected

    SELF_REF = '.'
    PARENT = '..'

    RULE_2A = %r{/\./|/\.$}
    RULE_2B_2C = %r{/([^/]*)/\.\./|/([^/]*)/\.\.$}
    RULE_2D = %r{^\.\.?/?}
    RULE_PREFIXED_PARENT = %r{^/\.\.?/|^(/\.\.?)+/?$}

    ##
    # Resolves paths to their simplest form.
    #
    # @param [String] path The path to normalize.
    #
    # @return [String] The normalized path.
    def self.normalize_path(path)
      # Section 5.2.4 of RFC 3986

      return if path.nil?

      normalized_path = path.dup
      loop do
        mod ||= normalized_path.gsub!(RULE_2A, SLASH)

        pair = normalized_path.match(RULE_2B_2C)
        if pair
          parent  = pair[1]
          current = pair[2]
        else
          parent  = nil
          current = nil
        end

        regexp = "/#{Regexp.escape(parent.to_s)}/\\.\\./|"
        regexp += "(/#{Regexp.escape(current.to_s)}/\\.\\.$)"

        if pair && ((parent != SELF_REF && parent != PARENT) ||
            (current != SELF_REF && current != PARENT))
          mod ||= normalized_path.gsub!(Regexp.new(regexp), SLASH)
        end

        mod ||= normalized_path.gsub!(RULE_2D, EMPTY_STR)
        # Non-standard, removes prefixed dotted segments from path.
        mod ||= normalized_path.gsub!(RULE_PREFIXED_PARENT, SLASH)
        break if mod.nil?
      end

      normalized_path
    end

    ##
    # Ensures that the URI is valid.
    def validate
      return if !!@validation_deferred

      if !scheme.nil? && ip_based? &&
         (host.nil? || host.empty?) &&
         (path.nil? || path.empty?)
        raise InvalidURIError,
              "Absolute URI missing hierarchical segment: '#{self}'"
      end
      if host.nil? && (!port.nil? ||
           !user.nil? ||
           !password.nil?)
        raise InvalidURIError, "Hostname not supplied: '#{self}'"
      end

      if !path.nil? && !path.empty? && path[0..0] != SLASH &&
         !authority.nil?
        raise InvalidURIError,
              "Cannot have a relative path with an authority set: '#{self}'"
      end
      if !path.nil? && !path.empty? &&
         path[0..1] == SLASH + SLASH && authority.nil?
        raise InvalidURIError,
              'Cannot have a path with two leading slashes ' +
              "without an authority set: '#{self}'"
      end
      unreserved = CharacterClasses::UNRESERVED
      sub_delims = CharacterClasses::SUB_DELIMS
      if !host.nil? && (host =~ %r{[<>{}/\\\?\#\@"[[:space:]]]} ||
          (host[/^\[(.*)\]$/, 1] != nil && host[/^\[(.*)\]$/, 1] !~
          Regexp.new("^[#{unreserved}#{sub_delims}:]*$")))
        raise InvalidURIError, "Invalid character in host: '#{host}'"
      end

      nil
    end

    ##
    # Replaces the internal state of self with the specified URI's state.
    # Used in destructive operations to avoid massive code repetition.
    #
    # @param [Addressable::URI] uri The URI to replace <code>self</code> with.
    #
    # @return [Addressable::URI] <code>self</code>.
    def replace_self(uri)
      # Reset dependent values
      reset_ivs

      @scheme = uri.scheme
      @user = uri.user
      @password = uri.password
      @host = uri.host
      @port = uri.port
      @path = uri.path
      @query = uri.query
      @fragment = uri.fragment
      self
    end

    ##
    # Splits path string with "/" (slash).
    # It is considered that there is empty string after last slash when
    # path ends with slash.
    #
    # @param [String] path The path to split.
    #
    # @return [Array<String>] An array of parts of path.
    def split_path(path)
      splitted = path.split(SLASH)
      splitted << EMPTY_STR if path.end_with? SLASH
      splitted
    end

    ##
    # Resets composite values for the entire URI
    #
    # @api private
    def remove_composite_values
      @uri_string = nil
      @hash = nil
    end

    ##
    # Converts the string to be UTF-8 if it is not already UTF-8
    #
    # @api private
    def force_utf8_encoding_if_needed(str)
      return unless str && str.encoding != Encoding::UTF_8

      str.force_encoding(Encoding::UTF_8)
    end

    private

    ##
    # Resets instance variables
    #
    # @api private
    def reset_ivs
      @scheme = nil
      @user = nil
      @normalized_scheme = NONE
      @normalized_user = NONE
      @uri_string = nil
      @hash = nil
      @userinfo = nil
      @normalized_userinfo = NONE
      @authority = nil
      @password = nil
      @normalized_authority = nil
      @port = nil
      @normalized_password = NONE
      @host = nil
      @normalized_host = nil
      @normalized_port = NONE
      @path = EMPTY_STR
      @normalized_path = nil
      @normalized_query = NONE
      @fragment = nil
      @normalized_fragment = NONE
      @query = nil
    end

    NONE = Module.new.freeze

    private_constant :NONE
  end
end
