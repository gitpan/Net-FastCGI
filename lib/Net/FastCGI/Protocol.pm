package Net::FastCGI::Protocol;

use strict;
use warnings;

use Carp                   qw[croak];
use Net::FastCGI           qw[];
use Net::FastCGI::Constant qw[:type FCGI_KEEP_CONN];

BEGIN {
    our $VERSION   = 0.09;
    our @EXPORT_OK = qw[ build_begin_request
                         build_begin_request_body
                         build_begin_request_record
                         build_end_request
                         build_end_request_body
                         build_end_request_record
                         build_header
                         build_params
                         build_record
                         build_stream
                         build_unknown_type_body
                         build_unknown_type_record
                         check_params
                         parse_begin_request_body
                         parse_end_request_body
                         parse_header
                         parse_params
                         parse_record
                         parse_record_body
                         parse_unknown_type_body
                         get_type_name
                         get_role_name
                         get_protocol_status_name
                         is_known_type
                         is_management_type
                         is_discrete_type
                         is_stream_type ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    my $use_pp = $ENV{NET_FASTCGI_PP} || $ENV{NET_FASTCGI_PROTOCOL_PP};

    if (!$use_pp) {
        eval {
            require Net::FastCGI::XS;
        };
    }

    if ($use_pp || $@) {
        require Net::FastCGI::Protocol::PP;
        Net::FastCGI::Protocol::PP->import(@EXPORT_OK);
    }
    else {
        require Net::FastCGI::Protocol::XS;
        Net::FastCGI::Protocol::XS->import(@EXPORT_OK);
    }

    # shared between XS and PP implementation
    push @EXPORT_OK, 'dump_record';

    require Exporter;
    *import = \&Exporter::import;
}

our $DUMP_RECORD_LEN   = 78;   # undocumented
our $DUMP_RECORD_ALIGN = !!0;  # undocumented

my %ESCAPES = (
    "\a"   => "\\a",
    "\b"   => "\\b",
    "\t"   => "\\t",
    "\n"   => "\\n",
    "\x0B" => "\\v",
    "\f"   => "\\f",
    "\r"   => "\\r",
);

sub dump_record {
    @_ == 2 || @_ == 3 || croak(q/Usage: dump_record(type, request_id [, content])/);
    my ($type, $request_id, $content) = @_;

    $content = ''
      unless defined $content;

    my $max = $DUMP_RECORD_LEN > 0 ? $DUMP_RECORD_LEN : ~0;
    my $out = '';

    if (   $type == FCGI_PARAMS
        || $type == FCGI_GET_VALUES
        || $type == FCGI_GET_VALUES_RESULT) {
        if (length $content == 0) {
            $out = q[""];
        }
        elsif (check_params($content)) {
            my ($off, $klen, $vlen) = (0);
            while ($off < length $content) {
                my $pos = $off;
                for ($klen, $vlen) {
                    $_ = unpack('C', substr($content, $off, 1));
                    $_ = unpack('N', substr($content, $off, 4)) & 0x7FFF_FFFF
                      if $_ > 0x7F;
                    $off += $_ > 0x7F ? 4 : 1;
                }

                my $head = substr($content, $pos, $off - $pos);
                   $head =~ s/(.)/sprintf('\\%.3o',ord($1))/egs;
                $out .= $head;

                my $body = substr($content, $off, $klen + $vlen);
                for ($body) {
                    s/([\\\"])/\\$1/g;
                    s/([\a\b\t\n\x0B\f\r])/$ESCAPES{$1}/g;
                    s/([^\x20-\x7E])/sprintf('\\x%.2X',ord($1))/eg;
                }
                $out .= $body;
                $off += $klen + $vlen;
                last if $off > $max;
            }
            substr($out, $max - 5) = ' ... '
              if length $out > $max;
            $out = qq["$out"];
        }
        else {
            $out = 'Malformed FCGI_NameValuePair(s)';
        }
    }
    elsif (   $type == FCGI_BEGIN_REQUEST
           || $type == FCGI_END_REQUEST
           || $type == FCGI_UNKNOWN_TYPE) {
        if (length $content != 8) {
            my $name = $type == FCGI_BEGIN_REQUEST ? 'FCGI_BeginRequestBody'
                     : $type == FCGI_END_REQUEST   ? 'FCGI_EndRequestBody'
                     :                               'FCGI_UnknownTypeBody';
            $out = sprintf 'Malformed %s (expected 8 octets got %d)', $name, length $content;
        }
        else {
            if ($type == FCGI_BEGIN_REQUEST) {
                my ($role, $flags) = parse_begin_request_body($content);
                if ($flags != 0) {
                    my @set;
                    if ($flags & FCGI_KEEP_CONN) {
                        $flags &= ~FCGI_KEEP_CONN;
                        push @set, 'FCGI_KEEP_CONN';
                    }
                    if ($flags) {
                        push @set, sprintf '0x%.2X', $flags;
                    }
                    $flags = join '|', @set;
                }
                $out = sprintf '{%s, %s}', get_role_name($role), $flags;
            }
            elsif($type == FCGI_END_REQUEST) {
                my ($astatus, $pstatus) = parse_end_request_body($content);
                $out = sprintf '{%d, %s}', $astatus, get_protocol_status_name($pstatus);
            }
            else {
                my $unknown_type = parse_unknown_type_body($content);
                $out = sprintf '{%s}', get_type_name($unknown_type);
            }
        }
    }
    elsif (length $content) {
        my $looks_like_binary = do {
            my $count = () = $content =~ /[\r\n\t\x20-\x7E]/g;
            ($count / length $content) < 0.7;
        };
        $out = substr($content, 0, $max);
        for ($out) {
            if ($looks_like_binary) {
                s/(.)/sprintf('\\x%.2X',ord($1))/egs;
            }
            else {
                s/([\\\"])/\\$1/g;
                s/([\a\b\t\n\x0B\f\r])/$ESCAPES{$1}/g;
                s/([^\x20-\x7E])/sprintf('\\x%.2X',ord($1))/eg;
            }
        }
        substr($out, $max - 5) = ' ... '
          if length $out > $max;
        $out = qq["$out"];
    }
    else {
        $out = q[""];
    }

    my $name  = get_type_name($type);
    my $width = 0;
       $width = 27 - length $name   #   length("FCGI_GET_VALUES_RESULT") == 22
         if $DUMP_RECORD_ALIGN;     # + length(0xFFFF) == 5
    return sprintf '{%s, %*d, %s}', $name, $width, $request_id, $out;
}

1;

