# trade reconciliation

run with:
perl reconcile_report.pl

testing:
prove -lv


caveats:
1 not the most efficient answer, match itself could be a class, may need refactoring
2 uses 'smart match' operator at ReconciliationReport.pm line 177, could be replaced with something like any from List::Util 

