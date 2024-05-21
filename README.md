# MariaDB10_for_DBIx_Schema_Loader
Provide MariaDB 10 client compatibility with DBIx::Clas::Schema::Loader

Background:

Older MariaDB clients, such as MariaDB 5, were supported by DBD::mysql. However, DBD::mysql intentionally no longer supports newer versions of MariaDB. The DBD::mysql module will not load on a server that uses MariaDB 10. DBD::MariaDB and DBIx::Class::Storage::DBI::MariaDB are existing CPAN modules that provide significant MariaDB capability. Even so, DBIx::Class::Schema::Loader fails to produce correct Schema/Result output when using the DBD::MariaDB driver. Problems encountered included missing primary keys entries, missing auto_increment entries and missing unsigned integer entries for all Result Classes which should have them.

Solution:

The solution is a two part fix. 1) A MariaDB.pm package needs to be included in the DBIx/Class/Schema/Loader/DBI directory 2) Since DBIx::Class::Schema::Loader depends on DBIx::Class::SQLMaker, a MariaDB.pm package needs to be included in the DBIx/Class/SQLMaker directory.

Action:

Pull requests providing the necessary MariaDB.pm files are being made with the maintainers of DBIx::Class::Schema::Loader and DBIx::Class. Both modules need their respective MariaDB.pm file added before the 'make_schema_at' capabiltiy of schema loader works correctly.

This branch addresses just part 1 of the fix, providing the MariaDB.pm file that needs to be added to the DBIx/Class/Schema/Loader/DBI directory.

Part two of the fix is contained in a separate pull request for DBIx::Class, entitled MariaDB10_for_DBIx_Class_SQLMaker.
