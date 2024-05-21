use strict;
use warnings;
use Test::More;
use Scope::Guard ();
use DBIx::Class::Optional::Dependencies;
use DBIx::Class::Schema::Loader::Utils qw/sigwarn_silencer/;
use lib qw(t/lib);
use dbixcsl_common_tests;

my %dsns;
for (qw(FIREBIRD FIREBIRD_ODBC FIREBIRD_INTERBASE)) {
    next unless $ENV{"DBICTEST_${_}_DSN"};

    my $dep_group = lc "rdbms_$_";
    if (!DBIx::Class::Optional::Dependencies->req_ok_for($dep_group)) {
        diag 'You need to install ' . DBIx::Class::Optional::Dependencies->req_missing_for($dep_group)
            . " to test with $_";
        next;
    }

    $dsns{$_}{dsn} = $ENV{"DBICTEST_${_}_DSN"};
    $dsns{$_}{user} = $ENV{"DBICTEST_${_}_USER"};
    $dsns{$_}{password} = $ENV{"DBICTEST_${_}_PASS"};
    $dsns{$_}{connect_info_opts} = { on_connect_call => 'use_softcommit' }
        if /\AFIREBIRD(?:_INTERBASE)?\z/;
};

plan skip_all => 'You need to set the DBICTEST_FIREBIRD_DSN, _USER and _PASS and/or the DBICTEST_FIREBIRD_ODBC_DSN, _USER and _PASS and/or the DBICTEST_FIREBIRD_INTERBASE_DSN, _USER and _PASS environment variables'
    unless %dsns;

my $schema;

my $tester = dbixcsl_common_tests->new(
    vendor      => 'Firebird',
    auto_inc_pk => 'INTEGER NOT NULL PRIMARY KEY',
    auto_inc_cb => sub {
        my ($table, $col) = @_;
        return (
            qq{ CREATE GENERATOR gen_${table}_${col} },
            qq{
                CREATE TRIGGER ${table}_bi FOR $table
                ACTIVE BEFORE INSERT POSITION 0
                AS
                BEGIN
                 IF (NEW.$col IS NULL) THEN
                  NEW.$col = GEN_ID(gen_${table}_${col},1);
                END
            }
        );
    },
    auto_inc_drop_cb => sub {
        my ($table, $col) = @_;
        return (
            qq{ DROP TRIGGER ${table}_bi },
            qq{ DROP GENERATOR gen_${table}_${col} },
        );
    },
    null        => '',
    preserve_case_mode_is_exclusive => 1,
    quote_char                      => '"',
    connect_info => [ map { $dsns{$_} } sort keys %dsns ],
    data_types  => {
        # based on the Interbase Data Definition Guide
        # http://www.ibphoenix.com/downloads/60DataDef.zip
        #
        # Numeric types
        'smallint'    => { data_type => 'smallint' },
        'int'         => { data_type => 'integer' },
        'integer'     => { data_type => 'integer' },
        'bigint'      => { data_type => 'bigint' },
        'float'       => { data_type => 'real' },
        'double precision' =>
                         { data_type => 'double precision' },
        'real'        => { data_type => 'real' },

        'float(2)'    => { data_type => 'real' },
        'float(7)'    => { data_type => 'real' },
        'float(8)'    => { data_type => 'double precision' },

        'decimal'     => { data_type => 'decimal' },
        'dec'         => { data_type => 'decimal' },
        'numeric'     => { data_type => 'numeric' },

        'decimal(3)'   => { data_type => 'decimal', size => [3,0] },

        'decimal(3,3)' => { data_type => 'decimal', size => [3,3] },
        'dec(3,3)'     => { data_type => 'decimal', size => [3,3] },
        'numeric(3,3)' => { data_type => 'numeric', size => [3,3] },

        'decimal(6,3)' => { data_type => 'decimal', size => [6,3] },
        'numeric(6,3)' => { data_type => 'numeric', size => [6,3] },

        'decimal(12,3)' => { data_type => 'decimal', size => [12,3] },
        'numeric(12,3)' => { data_type => 'numeric', size => [12,3] },

        'decimal(18,18)' => { data_type => 'decimal', size => [18,18] },
        'dec(18,18)'     => { data_type => 'decimal', size => [18,18] },
        'numeric(18,18)' => { data_type => 'numeric', size => [18,18] },

        # Date and Time Types
        'date'        => { data_type => 'date' },
        'timestamp default current_timestamp'
                      => { data_type => 'timestamp', default_value => \'current_timestamp' },
        'time'        => { data_type => 'time' },

        # String Types
        'char'         => { data_type => 'char',      size => 1  },
        'char(11)'     => { data_type => 'char',      size => 11 },
        'varchar(20)'  => { data_type => 'varchar',   size => 20 },
        'char(22) character set unicode_fss' =>
                       => { data_type => 'char(x) character set unicode_fss', size => 22 },
        'varchar(33) character set unicode_fss' =>
                       => { data_type => 'varchar(x) character set unicode_fss', size => 33 },

        # Blob types
        'blob'        => { data_type => 'blob' },
        'blob sub_type text'
                      => { data_type => 'blob sub_type text' },
        'blob sub_type text character set unicode_fss'
                      => { data_type => 'blob sub_type text character set unicode_fss' },
    },
    extra => {
        count  => 11,
        create => [
            q{
                CREATE TABLE "Firebird_Loader_Test1" (
                    "Id" INTEGER NOT NULL PRIMARY KEY,
                    "Foo" INTEGER DEFAULT 42
                )
            },
            q{
                CREATE GENERATOR "Gen_Firebird_Loader_Test1_Id"
            },
            q{
                CREATE TRIGGER "Firebird_Loader_Test1_BI" for "Firebird_Loader_Test1"
                ACTIVE BEFORE INSERT POSITION 0
                AS
                BEGIN
                 IF (NEW."Id" IS NULL) THEN
                  NEW."Id" = GEN_ID("Gen_Firebird_Loader_Test1_Id",1);
                END
            },
            q{
                CREATE VIEW firebird_loader_test2 AS SELECT * FROM "Firebird_Loader_Test1"
            },
        ],
        pre_drop_ddl => [
            'DROP VIEW firebird_loader_test2',
            'DROP TRIGGER "Firebird_Loader_Test1_BI"',
            'DROP GENERATOR "Gen_Firebird_Loader_Test1_Id"',
            'DROP TABLE "Firebird_Loader_Test1"',
        ],
        run    => sub {
            $schema = shift;
            my ($monikers, $classes, $self) = @_;

            my $dbh = $schema->storage->dbh;

# create a mixed case table
            $dbh->do($_) for (
            );

            local $schema->loader->{preserve_case} = 1;
            $schema->loader->_setup;

            $self->rescan_without_warnings($schema);

            ok ((my $rsrc = eval { $schema->resultset('FirebirdLoaderTest1')->result_source }),
                'got rsrc for mixed case table');

            ok ((my $col_info = eval { $rsrc->column_info('Id') }),
                'got column_info for column Id');

            is $col_info->{accessor}, 'id', 'column Id has lowercase accessor "id"';

            is $col_info->{is_auto_increment}, 1, 'is_auto_increment detected for mixed case trigger';

            is $col_info->{sequence}, 'Gen_Firebird_Loader_Test1_Id', 'correct mixed case sequence name';

            is eval { $rsrc->column_info('Foo')->{default_value} }, 42, 'default_value detected for mixed case column';

            # test that views are marked as such
            my $view_source = $schema->resultset($monikers->{firebird_loader_test2})->result_source;
            isa_ok $view_source, 'DBIx::Class::ResultSource::View',
                'view result source';

            like $view_source->view_definition,
                qr/\A \s* select\b .* \bfrom \s+ (?-i:"Firebird_Loader_Test1") \s* \z/imsx,
                'view definition';

            # test the fixed up ->_dbh_type_info_type_name for the ODBC driver
            if ($schema->storage->_dbi_connect_info->[0] =~ /:ODBC:/i) {
                my %truncated_types = (
                      4 => 'INTEGER',
                     -9 => 'VARCHAR(x) CHARACTER SET UNICODE_FSS',
                    -10 => 'BLOB SUB_TYPE TEXT CHARACTER SET UNICODE_FSS',
                );

                for my $type_num (keys %truncated_types) {
                    is $schema->loader->_dbh_type_info_type_name($type_num),
                        $truncated_types{$type_num},
                        "ODBC ->_dbh_type_info_type_name correct for '$truncated_types{$type_num}'";
                }
            }
            else {
                my $tb = Test::More->builder;
                $tb->skip('not testing _dbh_type_info_type_name on DBD::InterBase') for 1..3;
            }
        },
    },
);

{
    # get rid of stupid warning from InterBase/GetInfo.pm
    if ($dsns{FIREBIRD_INTERBASE}) {
        local $SIG{__WARN__} = sigwarn_silencer(
            qr{^(?:Use of uninitialized value|Argument "[0-9_]+" isn't numeric|Missing argument) in sprintf at \S+DBD/InterBase/GetInfo.pm line \d+\.$}
        );
        require DBD::InterBase;
        require DBD::InterBase::GetInfo;
    }

    $tester->run_tests();
}

# vim:et sts=4 sw=4 tw=0:
