package Net::FastCGI::Protocol;

use strict;
use warnings;

use Net::FastCGI qw[];

BEGIN {
    our $VERSION   = 0.01;
    our @EXPORT_OK = qw[ build_begin_request_body
                         build_begin_request_record
                         build_end_request_body
                         build_end_request_record
                         build_header
                         build_padding
                         build_params
                         build_params_pair
                         build_params_pair_header
                         build_record
                         build_unknown_type_body
                         build_unknown_type_record
                         parse_begin_request_body
                         parse_end_request_body
                         parse_header
                         parse_params
                         parse_params_pair
                         parse_params_pair_header
                         parse_unknown_type_body
                         compute_padding_length
                         compute_params_length
                         compute_params_pair_header_length
                         compute_params_pair_length
                         compute_record_length
                         get_type_name
                         get_role_name
                         get_protocol_status_name
                         is_known_type
                         is_management_type
                         is_discrete_type
                         is_stream_type ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    if ( Net::FastCGI::HAVE_XS ) {
        require Net::FastCGI::Protocol::XS;
        Net::FastCGI::Protocol::XS->import(@EXPORT_OK);
    }
    else {
        require Net::FastCGI::Protocol::PP;
        Net::FastCGI::Protocol::PP->import(@EXPORT_OK);
    }

    require Exporter;
    *import = \&Exporter::import;
}

1;
