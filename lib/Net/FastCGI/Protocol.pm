package Net::FastCGI::Protocol;

use strict;
use warnings;

use Net::FastCGI qw[];

BEGIN {
    our $VERSION   = 0.06;
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

    require Exporter;
    *import = \&Exporter::import;
}

1;

