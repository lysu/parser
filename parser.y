Start:
	StatementList

/**************************************AlterTableStmt***************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/alter-table.html
 *******************************************************************************************/
AlterTableStmt:
	ALTER IgnoreOptional TABLE TableName AlterTableSpecList
	{
		$$ = &ast.AlterTableStmt{
			Table: $4.(*ast.TableName),
			Specs: $5.([]*ast.AlterTableSpec),
		}
	}
|	ALTER IgnoreOptional TABLE TableName ANALYZE PARTITION PartitionNameList MaxNumBuckets
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$4.(*ast.TableName)}, PartitionNames: $7.([]model.CIStr), MaxNumBuckets: $8.(uint64),}
	}
|	ALTER IgnoreOptional TABLE TableName ANALYZE PARTITION PartitionNameList INDEX IndexNameList MaxNumBuckets
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames: []*ast.TableName{$4.(*ast.TableName)},
			PartitionNames: $7.([]model.CIStr),
			IndexNames: $9.([]model.CIStr),
			IndexFlag: true,
			MaxNumBuckets: $10.(uint64),
		}
	}

AlterTableSpec:
	AlterTableOptionListOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp:	ast.AlterTableOption,
			Options:$1.([]*ast.TableOption),
		}
	}
|	CONVERT TO CharsetKw CharsetName OptCollate
	{
		op := &ast.AlterTableSpec{
			Tp: ast.AlterTableOption,
			Options:[]*ast.TableOption{{Tp: ast.TableOptionCharset, StrValue: $4.(string)}},
		}
		if $5 !=  {
			op.Options = append(op.Options, &ast.TableOption{Tp: ast.TableOptionCollate, StrValue: $5.(string)})
		}
		$$ = op
	}
|	ADD ColumnKeywordOpt ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			Tp: 		ast.AlterTableAddColumns,
			NewColumns:	[]*ast.ColumnDef{$3.(*ast.ColumnDef)},
			Position:	$4.(*ast.ColumnPosition),
		}
	}
|	ADD ColumnKeywordOpt '(' ColumnDefList ')'
	{
		$$ = &ast.AlterTableSpec{
			Tp: 		ast.AlterTableAddColumns,
			NewColumns:	$4.([]*ast.ColumnDef),
		}
	}
|	ADD Constraint
	{
		constraint := $2.(*ast.Constraint)
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableAddConstraint,
			Constraint: constraint,
		}
	}
|	ADD PARTITION PartitionDefinitionListOpt
	{
		var defs []*ast.PartitionDefinition
		if $3 != nil {
			defs = $3.([]*ast.PartitionDefinition)
		}
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableAddPartitions,
			PartDefinitions: defs,
		}
	}
|	ADD PARTITION PARTITIONS NUM
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableAddPartitions,
			Num: getUint64FromNUM($4),
		}
	}
|	COALESCE PARTITION NUM
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableCoalescePartitions,
			Num: getUint64FromNUM($3),
		}
	}
|	DROP ColumnKeywordOpt ColumnName RestrictOrCascadeOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableDropColumn,
			OldColumnName: $3.(*ast.ColumnName),
		}
	}
|	DROP PRIMARY KEY
	{
		$$ = &ast.AlterTableSpec{Tp: ast.AlterTableDropPrimaryKey}
	}
|	DROP PARTITION Identifier
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableDropPartition,
			Name: $3,
		}
	}
|	TRUNCATE PARTITION Identifier
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableTruncatePartition,
			Name: $3,
		}
	}
|	DROP KeyOrIndex Identifier
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableDropIndex,
			Name: $3,
		}
	}
|	DROP FOREIGN KEY Symbol
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableDropForeignKey,
			Name: $4.(string),
		}
	}
|	DISABLE KEYS
	{
		$$ = &ast.AlterTableSpec{}
	}
|	ENABLE KEYS
	{
		$$ = &ast.AlterTableSpec{}
	}
|	MODIFY ColumnKeywordOpt ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			Tp:		ast.AlterTableModifyColumn,
			NewColumns:	[]*ast.ColumnDef{$3.(*ast.ColumnDef)},
			Position:	$4.(*ast.ColumnPosition),
		}
	}
|	CHANGE ColumnKeywordOpt ColumnName ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableChangeColumn,
			OldColumnName:	$3.(*ast.ColumnName),
			NewColumns:	[]*ast.ColumnDef{$4.(*ast.ColumnDef)},
			Position:	$5.(*ast.ColumnPosition),
		}
	}
|	ALTER ColumnKeywordOpt ColumnName SET DEFAULT SignedLiteral
	{
		option := &ast.ColumnOption{Expr: $6}
		colDef := &ast.ColumnDef{
			Name: 	 $3.(*ast.ColumnName),
			Options: []*ast.ColumnOption{option},
		}
		$$ = &ast.AlterTableSpec{
			Tp:		ast.AlterTableAlterColumn,
			NewColumns:	[]*ast.ColumnDef{colDef},
		}
	}
|	ALTER ColumnKeywordOpt ColumnName DROP DEFAULT
	{
		colDef := &ast.ColumnDef{
			Name: 	 $3.(*ast.ColumnName),
		}
		$$ = &ast.AlterTableSpec{
			Tp:		ast.AlterTableAlterColumn,
			NewColumns:	[]*ast.ColumnDef{colDef},
		}
	}
|	RENAME TO TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableRenameTable,
			NewTable:      $3.(*ast.TableName),
		}
	}
|	RENAME TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableRenameTable,
			NewTable:      $2.(*ast.TableName),
		}
	}
|	RENAME AS TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableRenameTable,
			NewTable:      $3.(*ast.TableName),
		}
	}
|	RENAME KeyOrIndex Identifier TO Identifier
	{
		$$ = &ast.AlterTableSpec{
			Tp:    	    ast.AlterTableRenameIndex,
			FromKey:    model.NewCIStr($3),
			ToKey:      model.NewCIStr($5),
		}
	}
|	LockClause
	{
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableLock,
			LockType:   $1.(ast.LockType),
		}
	}
| ALGORITHM EqOpt AlterAlgorithm
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableAlgorithm,
		}
	}
| FORCE
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp:    		ast.AlterTableForce,
		}
	}


AlterAlgorithm:
	DEFAULT
| INPLACE
| COPY

LockClauseOpt:
	{}
| 	LockClause {}

LockClause:
	LOCK eq NONE
	{
		$$ = ast.LockTypeNone
	}
|	LOCK eq DEFAULT
	{
		$$ = ast.LockTypeDefault
	}
|	LOCK eq SHARED
	{
		$$ = ast.LockTypeShared
	}
|	LOCK eq EXCLUSIVE
	{
		$$ = ast.LockTypeExclusive
	}

KeyOrIndex: KEY
| INDEX


KeyOrIndexOpt:
	{}
|	KeyOrIndex

ColumnKeywordOpt:
	{}
|	COLUMN

ColumnPosition:
	{
		$$ = &ast.ColumnPosition{Tp: ast.ColumnPositionNone}
	}
|	FIRST
	{
		$$ = &ast.ColumnPosition{Tp: ast.ColumnPositionFirst}
	}
|	AFTER ColumnName
	{
		$$ = &ast.ColumnPosition{
			Tp: ast.ColumnPositionAfter,
			RelativeColumn: $2.(*ast.ColumnName),
		}
	}

AlterTableSpecList:
	AlterTableSpec
	{
		$$ = []*ast.AlterTableSpec{$1.(*ast.AlterTableSpec)}
	}
|	AlterTableSpecList ',' AlterTableSpec
	{
		$$ = append($1.([]*ast.AlterTableSpec), $3.(*ast.AlterTableSpec))
	}

PartitionNameList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	PartitionNameList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

ConstraintKeywordOpt:
	{
		$$ = nil
	}
|	CONSTRAINT
	{
		$$ = nil
	}
|	CONSTRAINT Symbol
	{
		$$ = $2.(string)
	}

Symbol:
	Identifier
	{
		$$ = $1
	}

/**************************************RenameTableStmt***************************************
 * See http://dev.mysql.com/doc/refman/5.7/en/rename-table.html
 *
 * TODO: refactor this when you are going to add full support for multiple schema changes.
 * Currently it is only useful for syncer which depends heavily on tidb parser to do some dirty work.
 *******************************************************************************************/
RenameTableStmt:
	RENAME TABLE TableToTableList
	{
		$$ = &ast.RenameTableStmt{
			OldTable: $3.([]*ast.TableToTable)[0].OldTable,
			NewTable: $3.([]*ast.TableToTable)[0].NewTable,
			TableToTables: $3.([]*ast.TableToTable),
		}
	}

TableToTableList:
	TableToTable
	{
		$$ = []*ast.TableToTable{$1.(*ast.TableToTable)}
	}
|	TableToTableList ',' TableToTable
	{
		$$ = append($1.([]*ast.TableToTable), $3.(*ast.TableToTable))
	}

TableToTable:
	TableName TO TableName
	{
		$$ = &ast.TableToTable{
			OldTable: $1.(*ast.TableName),
			NewTable: $3.(*ast.TableName),
		}
	}


/*******************************************************************************************/

AnalyzeTableStmt:
	ANALYZE TABLE TableNameList MaxNumBuckets
	 {
		$$ = &ast.AnalyzeTableStmt{TableNames: $3.([]*ast.TableName), MaxNumBuckets: $4.(uint64)}
	 }
|	ANALYZE TABLE TableName INDEX IndexNameList MaxNumBuckets
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$3.(*ast.TableName)}, IndexNames: $5.([]model.CIStr), IndexFlag: true, MaxNumBuckets: $6.(uint64)}
	}
|	ANALYZE TABLE TableName PARTITION PartitionNameList MaxNumBuckets
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$3.(*ast.TableName)}, PartitionNames: $5.([]model.CIStr), MaxNumBuckets: $6.(uint64),}
	}
|	ANALYZE TABLE TableName PARTITION PartitionNameList INDEX IndexNameList MaxNumBuckets
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames: []*ast.TableName{$3.(*ast.TableName)},
			PartitionNames: $5.([]model.CIStr),
			IndexNames: $7.([]model.CIStr),
			IndexFlag: true,
			MaxNumBuckets: $8.(uint64),
		}
	}

MaxNumBuckets:
	{
		$$ = uint64(0)
	}
|	WITH NUM BUCKETS
	{
		$$ = getUint64FromNUM($2)
	}

/*******************************************************************************************/
Assignment:
	ColumnName eq Expression
	{
		$$ = &ast.Assignment{Column: $1.(*ast.ColumnName), Expr:$3}
	}

AssignmentList:
	Assignment
	{
		$$ = []*ast.Assignment{$1.(*ast.Assignment)}
	}
|	AssignmentList ',' Assignment
	{
		$$ = append($1.([]*ast.Assignment), $3.(*ast.Assignment))
	}

AssignmentListOpt:
	/* EMPTY */
	{
		$$ = []*ast.Assignment{}
	}
|	AssignmentList

BeginTransactionStmt:
	BEGIN
	{
		$$ = &ast.BeginStmt{}
	}
|	START TRANSACTION
	{
		$$ = &ast.BeginStmt{}
	}
|	START TRANSACTION WITH CONSISTENT SNAPSHOT
	{
		$$ = &ast.BeginStmt{}
	}

BinlogStmt:
	BINLOG stringLit
	{
		$$ = &ast.BinlogStmt{Str: $2}
	}

ColumnDefList:
	ColumnDef
	{
		$$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
	}
|	ColumnDefList ',' ColumnDef
	{
		$$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
	}

ColumnDef:
	ColumnName Type ColumnOptionListOpt
	{
		$$ = &ast.ColumnDef{Name: $1.(*ast.ColumnName), Tp: $2.(*types.FieldType), Options: $3.([]*ast.ColumnOption)}
	}

ColumnName:
	Identifier
	{
		$$ = &ast.ColumnName{Name: model.NewCIStr($1)}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.ColumnName{Table: model.NewCIStr($1), Name: model.NewCIStr($3)}
	}
|	Identifier '.' Identifier '.' Identifier
	{
		$$ = &ast.ColumnName{Schema: model.NewCIStr($1), Table: model.NewCIStr($3), Name: model.NewCIStr($5)}
	}

ColumnNameList:
	ColumnName
	{
		$$ = []*ast.ColumnName{$1.(*ast.ColumnName)}
	}
|	ColumnNameList ',' ColumnName
	{
		$$ = append($1.([]*ast.ColumnName), $3.(*ast.ColumnName))
	}

ColumnNameListOpt:
	/* EMPTY */
	{
		$$ = []*ast.ColumnName{}
	}
|	ColumnNameList
	{
		$$ = $1.([]*ast.ColumnName)
	}

ColumnNameListOptWithBrackets:
	/* EMPTY */
	{
		$$ = []*ast.ColumnName{}
	}
|	'(' ColumnNameListOpt ')'
	{
		$$ = $2.([]*ast.ColumnName)
	}

CommitStmt:
	COMMIT
	{
		$$ = &ast.CommitStmt{}
	}

PrimaryOpt:
	{}
| PRIMARY

ColumnOption:
	NOT NULL
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionNotNull}
	}
|	NULL
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionNull}
	}
|	AUTO_INCREMENT
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionAutoIncrement}
	}
|	PrimaryOpt KEY
	{
		// KEY is normally a synonym for INDEX. The key attribute PRIMARY KEY
		// can also be specified as just KEY when given in a column definition.
		// See http://dev.mysql.com/doc/refman/5.7/en/create-table.html
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionPrimaryKey}
	}
|	UNIQUE %prec lowerThanKey
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionUniqKey}
	}
|	UNIQUE KEY
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionUniqKey}
	}
|	DEFAULT DefaultValueExpr
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionDefaultValue, Expr: $2}
	}
|	ON UPDATE NowSymOptionFraction
	{
		nowFunc := &ast.FuncCallExpr{FnName: model.NewCIStr(CURRENT_TIMESTAMP)}
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionOnUpdate, Expr: nowFunc}
	}
|	COMMENT stringLit
	{
		$$ =  &ast.ColumnOption{Tp: ast.ColumnOptionComment, Expr: ast.NewValueExpr($2)}
	}
|	CHECK '(' Expression ')'
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/create-table.html
		// The CHECK clause is parsed but ignored by all storage engines.
		$$ = &ast.ColumnOption{}
	}
|	GeneratedAlways AS '(' Expression ')' VirtualOrStored
	{
		startOffset := parser.startOffset(&yyS[yypt-2])
		endOffset := parser.endOffset(&yyS[yypt-1])
		expr := $4
		expr.SetText(parser.src[startOffset:endOffset])

		$$ = &ast.ColumnOption{
			Tp: ast.ColumnOptionGenerated,
			Expr: expr,
			Stored: $6.(bool),
		}
	}
|	ReferDef
	{
		$$ = &ast.ColumnOption{
			Tp: ast.ColumnOptionReference,
			Refer: $1.(*ast.ReferenceDef),
		}
	}

VirtualOrStored:
	{
		$$ = false
	}
|	VIRTUAL
	{
		$$ = false
	}
|	STORED
	{
		$$ = true
	}

ColumnOptionList:
	ColumnOption
	{
		$$ = []*ast.ColumnOption{$1.(*ast.ColumnOption)}
	}
|	ColumnOptionList ColumnOption
	{
		$$ = append($1.([]*ast.ColumnOption), $2.(*ast.ColumnOption))
	}

ColumnOptionListOpt:
	{
		$$ = []*ast.ColumnOption{}
	}
|	ColumnOptionList
	{
		$$ = $1.([]*ast.ColumnOption)
	}

ConstraintElem:
	PRIMARY KEY IndexName IndexTypeOpt '(' IndexColNameList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp: ast.ConstraintPrimaryKey,
			Keys: $6.([]*ast.IndexColName),
		}
		if $8 != nil {
			c.Option = $8.(*ast.IndexOption)
		}
		if $4 != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = $4.(model.IndexType)
		}
		$$ = c
	}
|	FULLTEXT KeyOrIndexOpt IndexName '(' IndexColNameList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:	ast.ConstraintFulltext,
			Keys:	$5.([]*ast.IndexColName),
			Name:	$3.(string),
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}
		$$ = c
	}
|	KeyOrIndex IndexName IndexTypeOpt '(' IndexColNameList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:	ast.ConstraintIndex,
			Keys:	$5.([]*ast.IndexColName),
			Name:	$2.(string),
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}
		if $3 != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = $3.(model.IndexType)
		}
		$$ = c
	}
|	UNIQUE KeyOrIndexOpt IndexName IndexTypeOpt '(' IndexColNameList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:	ast.ConstraintUniq,
			Keys:	$6.([]*ast.IndexColName),
			Name:	$3.(string),
		}
		if $8 != nil {
			c.Option = $8.(*ast.IndexOption)
		}
		if $4 != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = $4.(model.IndexType)
		}
		$$ = c
	}
|	FOREIGN KEY IndexName '(' IndexColNameList ')' ReferDef
	{
		$$ = &ast.Constraint{
			Tp:	ast.ConstraintForeignKey,
			Keys:	$5.([]*ast.IndexColName),
			Name:	$3.(string),
			Refer:	$7.(*ast.ReferenceDef),
		}
	}

ReferDef:
	REFERENCES TableName '(' IndexColNameList ')' OnDeleteOpt OnUpdateOpt
	{
		var onDeleteOpt *ast.OnDeleteOpt
		if $6 != nil {
			onDeleteOpt = $6.(*ast.OnDeleteOpt)
		}
		var onUpdateOpt *ast.OnUpdateOpt
		if $7 != nil {
			onUpdateOpt = $7.(*ast.OnUpdateOpt)
		}
		$$ = &ast.ReferenceDef{
			Table: $2.(*ast.TableName),
			IndexColNames: $4.([]*ast.IndexColName),
			OnDelete: onDeleteOpt,
			OnUpdate: onUpdateOpt,
		}
	}

GeneratedAlways: GENERATED ALWAYS


OnDeleteOpt:
	{
		$$ = &ast.OnDeleteOpt{}
	}
|	ON DELETE ReferOpt
	{
		$$ = &ast.OnDeleteOpt{ReferOpt: $3.(ast.ReferOptionType)}
	}

OnUpdateOpt:
	{
		$$ = &ast.OnUpdateOpt{}
	}
|	ON UPDATE ReferOpt
	{
		$$ = &ast.OnUpdateOpt{ReferOpt: $3.(ast.ReferOptionType)}
	}


ReferOpt:
	RESTRICT
	{
		$$ = ast.ReferOptionRestrict
	}
|	CASCADE
	{
		$$ = ast.ReferOptionCascade
	}
|	SET NULL
	{
		$$ = ast.ReferOptionSetNull
	}
|	NO ACTION
	{
		$$ = ast.ReferOptionNoAction
	}

/*
 * The DEFAULT clause specifies a default value for a column.
 * With one exception, the default value must be a constant;
 * it cannot be a function or an expression. This means, for example,
 * that you cannot set the default for a date column to be the value of
 * a function such as NOW() or CURRENT_DATE. The exception is that you
 * can specify CURRENT_TIMESTAMP as the default for a TIMESTAMP or DATETIME column.
 *
 * See http://dev.mysql.com/doc/refman/5.7/en/create-table.html
 *      https://github.com/mysql/mysql-server/blob/5.7/sql/sql_yacc.yy#L6832
 */
DefaultValueExpr:
	NowSymOptionFraction
| SignedLiteral

NowSymOptionFraction:
	NowSym
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(CURRENT_TIMESTAMP)}
	}
|	NowSymFunc '(' ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(CURRENT_TIMESTAMP)}
	}
|	NowSymFunc '(' NUM ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(CURRENT_TIMESTAMP)}
	}

/*
* See https://dev.mysql.com/doc/refman/5.7/en/date-and-time-functions.html#function_localtime
* TODO: Process other three keywords
*/
NowSymFunc:
	CURRENT_TIMESTAMP
| LOCALTIME
| LOCALTIMESTAMP
| builtinNow

NowSym:
	CURRENT_TIMESTAMP
| LOCALTIME
| LOCALTIMESTAMP


SignedLiteral:
	Literal
	{
		$$ = ast.NewValueExpr($1)
	}
|	'+' NumLiteral
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Plus, V: ast.NewValueExpr($2)}
	}
|	'-' NumLiteral
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Minus, V: ast.NewValueExpr($2)}
	}

NumLiteral:
	intLit
|	floatLit
|	decLit


CreateIndexStmt:
	CREATE CreateIndexStmtUnique INDEX Identifier IndexTypeOpt ON TableName '(' IndexColNameList ')' IndexOptionList LockClauseOpt
	{
		var indexOption *ast.IndexOption
		if $11 != nil {
			indexOption = $11.(*ast.IndexOption)
			if indexOption.Tp == model.IndexTypeInvalid {
				if $5 != nil {
					indexOption.Tp = $5.(model.IndexType)
				}
			}
		} else {
			indexOption = &ast.IndexOption{}
			if $5 != nil {
				indexOption.Tp = $5.(model.IndexType)
			}
		}
		$$ = &ast.CreateIndexStmt{
			Unique:        $2.(bool),
			IndexName:     $4,
			Table:         $7.(*ast.TableName),
			IndexColNames: $9.([]*ast.IndexColName),
			IndexOption:   indexOption,
		}
	}

CreateIndexStmtUnique:
	{
		$$ = false
	}
|	UNIQUE
	{
		$$ = true
	}

IndexColName:
	ColumnName OptFieldLen Order
	{
		//Order is parsed but just ignored as MySQL did
		$$ = &ast.IndexColName{Column: $1.(*ast.ColumnName), Length: $2.(int)}
	}

IndexColNameList:
	IndexColName
	{
		$$ = []*ast.IndexColName{$1.(*ast.IndexColName)}
	}
|	IndexColNameList ',' IndexColName
	{
		$$ = append($1.([]*ast.IndexColName), $3.(*ast.IndexColName))
	}



/*******************************************************************
 *
 *  Create Database Statement
 *  CREATE {DATABASE
| SCHEMA} [IF NOT EXISTS] db_name
 *      [create_specification] ...
 *
 *  create_specification:
 *      [DEFAULT] CHARACTER SET [=] charset_name
 *
| [DEFAULT] COLLATE [=] collation_name
 *******************************************************************/
CreateDatabaseStmt:
	CREATE DatabaseSym IfNotExists DBName DatabaseOptionListOpt
	{
		$$ = &ast.CreateDatabaseStmt{
			IfNotExists:	$3.(bool),
			Name:		$4.(string),
			Options:	$5.([]*ast.DatabaseOption),
		}
	}

DBName:
	Identifier
	{
		$$ = $1
	}

DatabaseOption:
	DefaultKwdOpt CharsetKw EqOpt CharsetName
	{
		$$ = &ast.DatabaseOption{Tp: ast.DatabaseOptionCharset, Value: $4.(string)}
	}
|	DefaultKwdOpt COLLATE EqOpt StringName
	{
		$$ = &ast.DatabaseOption{Tp: ast.DatabaseOptionCollate, Value: $4.(string)}
	}

DatabaseOptionListOpt:
	{
		$$ = []*ast.DatabaseOption{}
	}
|	DatabaseOptionList

DatabaseOptionList:
	DatabaseOption
	{
		$$ = []*ast.DatabaseOption{$1.(*ast.DatabaseOption)}
	}
|	DatabaseOptionList DatabaseOption
	{
		$$ = append($1.([]*ast.DatabaseOption), $2.(*ast.DatabaseOption))
	}

/*******************************************************************
 *
 *  Create Table Statement
 *
 *  Example:
 *      CREATE TABLE Persons
 *      (
 *          P_Id int NOT NULL,
 *          LastName varchar(255) NOT NULL,
 *          FirstName varchar(255),
 *          Address varchar(255),
 *          City varchar(255),
 *          PRIMARY KEY (P_Id)
 *      )
 *******************************************************************/

CreateTableStmt:
	CREATE TABLE IfNotExists TableName TableElementListOpt CreateTableOptionListOpt PartitionOpt DuplicateOpt AsOpt CreateTableSelectOpt
	{
		stmt := $5.(*ast.CreateTableStmt)
		stmt.Table = $4.(*ast.TableName)
		stmt.IfNotExists = $3.(bool)
		stmt.Options = $6.([]*ast.TableOption)
		if $7 != nil {
			stmt.Partition = $7.(*ast.PartitionOptions)
		}
		stmt.OnDuplicate = $8.(ast.OnDuplicateCreateTableSelectType)
		stmt.Select = $10.(*ast.CreateTableStmt).Select
		$$ = stmt
	}
|	CREATE TABLE IfNotExists TableName LikeTableWithOrWithoutParen
	{
		$$ = &ast.CreateTableStmt{
			Table:          $4.(*ast.TableName),
			ReferTable:	$5.(*ast.TableName),
			IfNotExists:    $3.(bool),
		}
	}

DefaultKwdOpt:
	{}
|	DEFAULT

PartitionOpt:
	{
		$$ = nil
	}
|	PARTITION BY KEY '(' ColumnNameList ')' PartitionNumOpt PartitionDefinitionListOpt
	{
		$$ = nil
	}
|	PARTITION BY HASH '(' Expression ')' PartitionNumOpt
	{
		tmp := &ast.PartitionOptions{
			Tp: model.PartitionTypeHash,
			Expr: $5.(ast.ExprNode),
			// If you do not include a PARTITIONS clause, the number of partitions defaults to 1
			Num: 1,
		}
		if $7 != nil {
			tmp.Num = getUint64FromNUM($7)
		}
		$$ = tmp
	}
|	PARTITION BY RANGE '(' Expression ')' PartitionNumOpt SubPartitionOpt PartitionDefinitionListOpt
	{
		var defs []*ast.PartitionDefinition
		if $9 != nil {
			defs = $9.([]*ast.PartitionDefinition)
		}
		$$ = &ast.PartitionOptions{
			Tp:		model.PartitionTypeRange,
			Expr:		$5.(ast.ExprNode),
			Definitions:	defs,
		}
	}
|	PARTITION BY RANGE COLUMNS '(' ColumnNameList ')' PartitionNumOpt PartitionDefinitionListOpt
	{
		var defs []*ast.PartitionDefinition
		if $9 != nil {
			defs = $9.([]*ast.PartitionDefinition)
		}
		$$ = &ast.PartitionOptions{
			Tp:		model.PartitionTypeRange,
			ColumnNames:	$6.([]*ast.ColumnName),
			Definitions:	defs,
		}
	}

SubPartitionOpt:
	{}
|	SUBPARTITION BY HASH '(' Expression ')' SubPartitionNumOpt
	{}
|	SUBPARTITION BY KEY '(' ColumnNameList ')' SubPartitionNumOpt
	{}

SubPartitionNumOpt:
	{}
|	SUBPARTITIONS NUM
	{}

PartitionNumOpt:
	{
		$$ = nil
	}
|	PARTITIONS NUM
	{
		$$ = $2
	}

PartitionDefinitionListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		$$ = nil
	}
|	'(' PartitionDefinitionList ')'
	{
		$$ = $2.([]*ast.PartitionDefinition)
	}

PartitionDefinitionList:
	PartitionDefinition
	{
		$$ = []*ast.PartitionDefinition{$1.(*ast.PartitionDefinition)}
	}
|	PartitionDefinitionList ',' PartitionDefinition
	{
		$$ = append($1.([]*ast.PartitionDefinition), $3.(*ast.PartitionDefinition))
	}

PartitionDefinition:
	PARTITION Identifier PartDefValuesOpt PartDefOptionsOpt
	{
		partDef := &ast.PartitionDefinition{
			Name: model.NewCIStr($2),
		}
		switch $3.(type) {
		case []ast.ExprNode:
			partDef.LessThan = $3.([]ast.ExprNode)
		case ast.ExprNode:
			partDef.LessThan = make([]ast.ExprNode, 1)
			partDef.LessThan[0] = $3.(ast.ExprNode)
		}

		if comment, ok := $4.(string); ok {
			partDef.Comment = comment
		}
		$$ = partDef
	}

PartDefOptionsOpt:
	{
		$$ = nil
	}
|	PartDefOptionList
	{
		$$ = $1
	}

PartDefOptionList:
	PartDefOption
	{
		$$ = $1
	}
|	PartDefOptionList PartDefOption
	{
		if $1 != nil {
			$$ = $1
		} else {
			$$ = $2
		}
	}

PartDefOption:
	COMMENT EqOpt stringLit
	{
		$$ = $3
	}
|	ENGINE EqOpt Identifier
	{
		$$ = nil
	}
|	TABLESPACE EqOpt Identifier
	{
		$$ =  nil
	}


PartDefValuesOpt:
	{
		$$ = nil
	}
|	VALUES LESS THAN MAXVALUE
	{
		$$ = &ast.MaxValueExpr{}
	}
|	VALUES LESS THAN '(' MaxValueOrExpressionList ')'
	{
		$$ = $5
	}

DuplicateOpt:
	{
		$$ = ast.OnDuplicateCreateTableSelectError
	}
|   IGNORE
	{
		$$ = ast.OnDuplicateCreateTableSelectIgnore
	}
|   REPLACE
	{
		$$ = ast.OnDuplicateCreateTableSelectReplace
	}

AsOpt:
	{}
|	AS
	{}

CreateTableSelectOpt:
	/* empty */
	{
		$$ = &ast.CreateTableStmt{}
	}
|
	SelectStmt
	{
		$$ = &ast.CreateTableStmt{Select: $1}
	}
|
	UnionStmt
	{
		$$ = &ast.CreateTableStmt{Select: $1}
	}
|
	SubSelect %prec createTableSelect
	// TODO: We may need better solution as issue #320.
	{
		$$ = &ast.CreateTableStmt{Select: $1}
	}

LikeTableWithOrWithoutParen:
	LIKE TableName
	{
		$$ = $2
	}
|
	'(' LIKE TableName ')'
	{
		$$ = $3
	}

/*******************************************************************
 *
 *  Create View Statement
 *
 *  Example:
 *      CREATE VIEW OR REPLACE ALGORITHM = MERGE DEFINER=root@localhost SQL SECURITY = definer view_name (col1,col2)
 *          as select Col1,Col2 from table WITH LOCAL CHECK OPTION
 *******************************************************************/
CreateViewStmt:
    CREATE OrReplace ViewAlgorithm ViewDefiner ViewSQLSecurity VIEW ViewName ViewFieldList AS SelectStmt ViewCheckOption
    {
		startOffset := parser.startOffset(&yyS[yypt-1])
		selStmt := $10.(*ast.SelectStmt)
		selStmt.SetText(strings.TrimSpace(parser.src[startOffset:]))
		x := &ast.CreateViewStmt {
 			OrReplace:     $2.(bool),
			ViewName:      $7.(*ast.TableName),
			Select:        selStmt,
			Algorithm:     $3.(model.ViewAlgorithm),
			Definer:       $4.(*auth.UserIdentity),
			Security:      $5.(model.ViewSecurity),
		}
		if $8 != nil{
			x.Cols = $8.([]model.CIStr)
		}
		if $11 !=nil {
		    x.CheckOption = $11.(model.ViewCheckOption)
		    endOffset := parser.startOffset(&yyS[yypt])
		    selStmt.SetText(strings.TrimSpace(parser.src[startOffset:endOffset]))
		} else {
		    x.CheckOption = model.CheckOptionCascaded
		}
		$$ = x
	}

OrReplace:
	{
		$$ = false
	}
|	OR REPLACE
	{
		$$ = true
	}

ViewAlgorithm:
	/* EMPTY */
	{
		$$ = model.AlgorithmUndefined
	}
|	ALGORITHM '=' UNDEFINED
	{
		$$ = model.AlgorithmUndefined
	}
|	ALGORITHM '=' MERGE
	{
		$$ = model.AlgorithmMerge
	}
|	ALGORITHM '=' TEMPTABLE
	{
		$$ = model.AlgorithmTemptable
	}

ViewDefiner:
	/* EMPTY */
	{
		$$ = &auth.UserIdentity{CurrentUser: true}
	}
|   DEFINER '=' Username
	{
		$$ = $3
	}

ViewSQLSecurity:
	/* EMPTY */
	{
		$$ = model.SecurityDefiner
	}
|   SQL SECURITY DEFINER
	 {
		 $$ = model.SecurityDefiner
	 }
|   SQL SECURITY INVOKER
	 {
		 $$ = model.SecurityInvoker
	 }

ViewName:
	TableName
	{
		$$ = $1.(*ast.TableName)
	}

ViewFieldList:
	/* Empty */
	{
		$$ = nil
	}
|   '(' ColumnList ')'
	{
		$$ = $2.([]model.CIStr)
	}

ColumnList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|   ColumnList ',' Identifier
	{
	$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

ViewCheckOption:
	/* EMPTY */
	{
		$$ = nil
	}
|   WITH CASCADED CHECK OPTION
	{
		$$ = model.CheckOptionCascaded
	}
|   WITH LOCAL CHECK OPTION
	{
		$$ = model.CheckOptionLocal
	}

/******************************************************************
 * Do statement
 * See https://dev.mysql.com/doc/refman/5.7/en/do.html
 ******************************************************************/
DoStmt:
	DO ExpressionList
	{
		$$ = &ast.DoStmt {
			Exprs: $2.([]ast.ExprNode),
		}
	}

/*******************************************************************
 *
 *  Delete Statement
 *
 *******************************************************************/
DeleteFromStmt:
	DELETE TableOptimizerHints PriorityOpt QuickOptional IgnoreOptional FROM TableName IndexHintListOpt WhereClauseOptional OrderByOptional LimitClause
	{
		// Single Table
		tn := $7.(*ast.TableName)
		tn.IndexHints = $8.([]*ast.IndexHint)
		join := &ast.Join{Left: &ast.TableSource{Source: tn}, Right: nil}
		x := &ast.DeleteStmt{
			TableRefs: &ast.TableRefsClause{TableRefs: join},
			Priority:  $3.(mysql.PriorityEnum),
			Quick:	   $4.(bool),
			IgnoreErr: $5.(bool),
		}
		if $9 != nil {
			x.Where = $9.(ast.ExprNode)
		}
		if $10 != nil {
			x.Order = $10.(*ast.OrderByClause)
		}
		if $11 != nil {
			x.Limit = $11.(*ast.Limit)
		}

		$$ = x
	}
|	DELETE TableOptimizerHints PriorityOpt QuickOptional IgnoreOptional TableNameList FROM TableRefs WhereClauseOptional
	{
		// Multiple Table
		x := &ast.DeleteStmt{
			Priority:	  $3.(mysql.PriorityEnum),
			Quick:		  $4.(bool),
			IgnoreErr:	  $5.(bool),
			IsMultiTable: 	  true,
			BeforeFrom:	  true,
			Tables:		  &ast.DeleteTableList{Tables: $6.([]*ast.TableName)},
			TableRefs:	  &ast.TableRefsClause{TableRefs: $8.(*ast.Join)},
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $9 != nil {
			x.Where = $9.(ast.ExprNode)
		}
		$$ = x
	}

|	DELETE TableOptimizerHints PriorityOpt QuickOptional IgnoreOptional FROM TableNameList USING TableRefs WhereClauseOptional
	{
		// Multiple Table
		x := &ast.DeleteStmt{
			Priority:	  $3.(mysql.PriorityEnum),
			Quick:		  $4.(bool),
			IgnoreErr:	  $5.(bool),
			IsMultiTable:	  true,
			Tables:		  &ast.DeleteTableList{Tables: $7.([]*ast.TableName)},
			TableRefs:	  &ast.TableRefsClause{TableRefs: $9.(*ast.Join)},
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $10 != nil {
			x.Where = $10.(ast.ExprNode)
		}
		$$ = x
	}

DatabaseSym:
DATABASE

DropDatabaseStmt:
	DROP DatabaseSym IfExists DBName
	{
		$$ = &ast.DropDatabaseStmt{IfExists: $3.(bool), Name: $4.(string)}
	}

DropIndexStmt:
	DROP INDEX IfExists Identifier ON TableName
	{
		$$ = &ast.DropIndexStmt{IfExists: $3.(bool), IndexName: $4, Table: $6.(*ast.TableName)}
	}

DropTableStmt:
	DROP TableOrTables TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{Tables: $3.([]*ast.TableName), IsView: false}
	}
|	DROP TableOrTables IF EXISTS TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{IfExists: true, Tables: $5.([]*ast.TableName), IsView: false}
	}

DropViewStmt:
	DROP VIEW TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{Tables: $3.([]*ast.TableName), IsView: true}
	}
|
	DROP VIEW IF EXISTS TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{IfExists: true, Tables: $5.([]*ast.TableName), IsView: true}
	}

DropUserStmt:
	DROP USER UsernameList
	{
		$$ = &ast.DropUserStmt{IfExists: false, UserList: $3.([]*auth.UserIdentity)}
	}
|	DROP USER IF EXISTS UsernameList
	{
		$$ = &ast.DropUserStmt{IfExists: true, UserList: $5.([]*auth.UserIdentity)}
	}

DropStatsStmt:
	DROP STATS TableName
	{
		$$ = &ast.DropStatsStmt{Table: $3.(*ast.TableName)}
	}

RestrictOrCascadeOpt:
	{}
|	RESTRICT
|	CASCADE

TableOrTables:
	TABLE
|	TABLES

EqOpt:
	{}
|	eq

EmptyStmt:
	/* EMPTY */
	{
		$$ = nil
	}

TraceStmt:
	TRACE TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt:	$2,
			Format: json,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$2.SetText(string(parser.src[startOffset:]))
	}
|	TRACE FORMAT '=' stringLit TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt: $5,
			Format: $4,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$5.SetText(string(parser.src[startOffset:]))
	}

ExplainSym:
EXPLAIN
| DESCRIBE
| DESC

ExplainStmt:
	ExplainSym TableName
	{
		$$ = &ast.ExplainStmt{
			Stmt: &ast.ShowStmt{
				Tp:	ast.ShowColumns,
				Table:	$2.(*ast.TableName),
			},
		}
	}
|	ExplainSym TableName ColumnName
	{
		$$ = &ast.ExplainStmt{
			Stmt: &ast.ShowStmt{
				Tp:	ast.ShowColumns,
				Table:	$2.(*ast.TableName),
				Column:	$3.(*ast.ColumnName),
			},
		}
	}
|	ExplainSym ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:	$2,
			Format: row,
		}
	}
|	ExplainSym FORMAT '=' stringLit ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:	$5,
			Format: $4,
		}
	}
|   ExplainSym ANALYZE ExplainableStmt
    {
        $$ = &ast.ExplainStmt {
            Stmt:   $3,
            Format: row,
            Analyze: true,
        }
    }

LengthNum:
	NUM
	{
		$$ = getUint64FromNUM($1)
	}

NUM:
	intLit

Expression:
	singleAtIdentifier assignmentEq Expression %prec assignmentEq
	{
		v := $1
		v = strings.TrimPrefix(v, @)
		$$ = &ast.VariableExpr{
				Name: 	  v,
				IsGlobal: false,
				IsSystem: false,
				Value:	  $3,
		}
	}
|	Expression logOr Expression %prec pipes
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicOr, L: $1, R: $3}
	}
|	Expression XOR Expression %prec xor
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicXor, L: $1, R: $3}
	}
|	Expression logAnd Expression %prec andand
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicAnd, L: $1, R: $3}
	}
|	NOT Expression %prec not
	{
		expr, ok := $2.(*ast.ExistsSubqueryExpr)
		if ok {
			expr.Not = true
			$$ = $2
		} else {
			$$ = &ast.UnaryOperationExpr{Op: opcode.Not, V: $2}
		}
	}
|	BoolPri IsOrNotOp trueKwd %prec is
	{
		$$ = &ast.IsTruthExpr{Expr:$1, Not: !$2.(bool), True: int64(1)}
	}
|	BoolPri IsOrNotOp falseKwd %prec is
	{
		$$ = &ast.IsTruthExpr{Expr:$1, Not: !$2.(bool), True: int64(0)}
	}
|	BoolPri IsOrNotOp UNKNOWN %prec is
	{
		/* https://dev.mysql.com/doc/refman/5.7/en/comparison-operators.html#operator_is */
		$$ = &ast.IsNullExpr{Expr: $1, Not: !$2.(bool)}
	}
|	BoolPri

MaxValueOrExpression:
	MAXVALUE
	{
		$$ = &ast.MaxValueExpr{}
	}
|	Expression
	{
		$$ = $1
	}


logOr:
	pipesAsOr
|	OR

logAnd:
'&&'
| AND

ExpressionList:
	Expression
	{
		$$ = []ast.ExprNode{$1}
	}
|	ExpressionList ',' Expression
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

MaxValueOrExpressionList:
	MaxValueOrExpression
	{
		$$ = []ast.ExprNode{$1}
}
|	MaxValueOrExpressionList ',' MaxValueOrExpression
{
		$$ = append($1.([]ast.ExprNode), $3)
	}


ExpressionListOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	ExpressionList

FuncDatetimePrecListOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	FuncDatetimePrecList
	{
		$$ = $1
	}

FuncDatetimePrecList:
	intLit
	{
		expr := ast.NewValueExpr($1)
		$$ = []ast.ExprNode{expr}
	}

BoolPri:
	BoolPri IsOrNotOp NULL %prec is
	{
		$$ = &ast.IsNullExpr{Expr: $1, Not: !$2.(bool)}
	}
|	BoolPri CompareOp PredicateExpr %prec eq
	{
		$$ = &ast.BinaryOperationExpr{Op: $2.(opcode.Op), L: $1, R: $3}
	}
|	BoolPri CompareOp AnyOrAll SubSelect %prec eq
	{
		sq := $4.(*ast.SubqueryExpr)
		sq.MultiRows = true
		$$ = &ast.CompareSubqueryExpr{Op: $2.(opcode.Op), L: $1, R: sq, All: $3.(bool)}
	}
|	BoolPri CompareOp singleAtIdentifier assignmentEq PredicateExpr %prec assignmentEq
	{
		v := $3
		v = strings.TrimPrefix(v, @)
		variable := &ast.VariableExpr{
				Name: 	  v,
				IsGlobal: false,
				IsSystem: false,
				Value:	  $5,
		}
		$$ = &ast.BinaryOperationExpr{Op: $2.(opcode.Op), L: $1, R: variable}
	}
|	PredicateExpr

CompareOp:
	'>='
	{
		$$ = opcode.GE
	}
|	'>'
	{
		$$ = opcode.GT
	}
|	'<='
	{
		$$ = opcode.LE
	}
|	'<'
	{
		$$ = opcode.LT
	}
|	'!='
	{
		$$ = opcode.NE
	}
|	'<>'
	{
		$$ = opcode.NE
	}
|	'='
	{
		$$ = opcode.EQ
	}
|	'<=>'
	{
		$$ = opcode.NullEQ
	}

BetweenOrNotOp:
	BETWEEN
	{
		$$ = true
	}
|	NOT BETWEEN
	{
		$$ = false
	}

IsOrNotOp:
	IS
	{
		$$ = true
	}
|	IS NOT
	{
		$$ = false
	}

InOrNotOp:
	IN
	{
		$$ = true
	}
|	NOT IN
	{
		$$ = false
	}

LikeOrNotOp:
	LIKE
	{
		$$ = true
	}
|	NOT LIKE
	{
		$$ = false
	}

RegexpOrNotOp:
	RegexpSym
	{
		$$ = true
	}
|	NOT RegexpSym
	{
		$$ = false
	}

AnyOrAll:
	ANY
	{
		$$ = false
	}
|	SOME
	{
		$$ = false
	}
|	ALL
	{
		$$ = true
	}

PredicateExpr:
	BitExpr InOrNotOp '(' ExpressionList ')'
	{
		$$ = &ast.PatternInExpr{Expr: $1, Not: !$2.(bool), List: $4.([]ast.ExprNode)}
	}
|	BitExpr InOrNotOp SubSelect
	{
		sq := $3.(*ast.SubqueryExpr)
		sq.MultiRows = true
		$$ = &ast.PatternInExpr{Expr: $1, Not: !$2.(bool), Sel: sq}
	}
|	BitExpr BetweenOrNotOp BitExpr AND PredicateExpr
	{
		$$ = &ast.BetweenExpr{
			Expr:	$1,
			Left:	$3,
			Right:	$5,
			Not:	!$2.(bool),
		}
	}
|	BitExpr LikeOrNotOp SimpleExpr LikeEscapeOpt
	{
		escape := $4.(string)
		if len(escape) > 1 {
			yylex.Errorf(Incorrect arguments %s to ESCAPE, escape)
			return 1
		} else if len(escape) == 0 {
			escape = \\
		}
		$$ = &ast.PatternLikeExpr{
			Expr:		$1,
			Pattern:	$3,
			Not: 		!$2.(bool),
			Escape: 	escape[0],
		}
	}
|	BitExpr RegexpOrNotOp SimpleExpr
	{
		$$ = &ast.PatternRegexpExpr{Expr: $1, Pattern: $3, Not: !$2.(bool)}
	}
|	BitExpr

RegexpSym:
REGEXP
| RLIKE

LikeEscapeOpt:
	%prec empty
	{
		$$ = \\
	}
|	ESCAPE stringLit
	{
		$$ = $2
	}

Field:
	'*'
	{
		$$ = &ast.SelectField{WildCard: &ast.WildCardField{}}
	}
|	Identifier '.' '*'
	{
		wildCard := &ast.WildCardField{Table: model.NewCIStr($1)}
		$$ = &ast.SelectField{WildCard: wildCard}
	}
|	Identifier '.' Identifier '.' '*'
	{
		wildCard := &ast.WildCardField{Schema: model.NewCIStr($1), Table: model.NewCIStr($3)}
		$$ = &ast.SelectField{WildCard: wildCard}
	}
|	Expression FieldAsNameOpt
	{
		expr := $1
		asName := $2.(string)
		$$ = &ast.SelectField{Expr: expr, AsName: model.NewCIStr(asName)}
	}
|	'{' Identifier Expression '}' FieldAsNameOpt
	{
		/*
		* ODBC escape syntax.
		* See https://dev.mysql.com/doc/refman/5.7/en/expressions.html
		*/
		expr := $3
		asName := $5.(string)
		$$ = &ast.SelectField{Expr: expr, AsName: model.NewCIStr(asName)}
	}

FieldAsNameOpt:
	/* EMPTY */
	{
		$$ =
	}
|	FieldAsName
	{
		$$ = $1
	}

FieldAsName:
	Identifier
	{
		$$ = $1
	}
|	AS Identifier
	{
		$$ = $2
	}
|	stringLit
	{
		$$ = $1
	}
|	AS stringLit
	{
		$$ = $2
	}

FieldList:
	Field
	{
		field := $1.(*ast.SelectField)
		field.Offset = parser.startOffset(&yyS[yypt])
		$$ = []*ast.SelectField{field}
	}
|	FieldList ',' Field
	{

		fl := $1.([]*ast.SelectField)
		last := fl[len(fl)-1]
		if last.Expr != nil && last.AsName.O ==  {
			lastEnd := parser.endOffset(&yyS[yypt-1])
			last.SetText(parser.src[last.Offset:lastEnd])
		}
		newField := $3.(*ast.SelectField)
		newField.Offset = parser.startOffset(&yyS[yypt])
		$$ = append(fl, newField)
	}

GroupByClause:
	GROUP BY ByList
	{
		$$ = &ast.GroupByClause{Items: $3.([]*ast.ByItem)}
	}

HavingClause:
	{
		$$ = nil
	}
|	HAVING Expression
	{
		$$ = &ast.HavingClause{Expr: $2}
	}

IfExists:
	{
		$$ = false
	}
|	IF EXISTS
	{
		$$ = true
	}

IfNotExists:
	{
		$$ = false
	}
|	IF NOT EXISTS
	{
		$$ = true
	}


IgnoreOptional:
	{
		$$ = false
	}
|	IGNORE
	{
		$$ = true
	}

IndexName:
	{
		$$ =
	}
|	Identifier
	{
		//index name
		$$ = $1
	}

IndexOptionList:
	{
		$$ = nil
	}
|	IndexOptionList IndexOption
	{
		// Merge the options
		if $1 == nil {
			$$ = $2
		} else {
			opt1 := $1.(*ast.IndexOption)
			opt2 := $2.(*ast.IndexOption)
			if len(opt2.Comment) > 0 {
				opt1.Comment = opt2.Comment
			} else if opt2.Tp != 0 {
				opt1.Tp = opt2.Tp
			} else if opt2.KeyBlockSize > 0 {
			    opt1.KeyBlockSize = opt2.KeyBlockSize
			}
			$$ = opt1
		}
	}


IndexOption:
	KEY_BLOCK_SIZE EqOpt LengthNum
	{
		$$ = &ast.IndexOption{
			KeyBlockSize: $3.(uint64),
		}
	}
|	IndexType
	{
		$$ = &ast.IndexOption {
			Tp: $1.(model.IndexType),
		}
	}
|	COMMENT stringLit
	{
		$$ = &ast.IndexOption {
			Comment: $2,
		}
	}

IndexType:
	USING BTREE
	{
		$$ = model.IndexTypeBtree
	}
|	USING HASH
	{
		$$ = model.IndexTypeHash
	}

IndexTypeOpt:
	{
		$$ = nil
	}
|	IndexType
	{
		$$ = $1
	}

/**********************************Identifier********************************************/
Identifier:
identifier
| UnReservedKeyword
| NotKeywordToken
| TiDBKeyword

UnReservedKeyword:
 ACTION
| ASCII
| AUTO_INCREMENT
| AFTER
| ALWAYS
| AVG
| BEGIN
| BIT
| BOOL
| BOOLEAN
| BTREE
| BYTE
| CLEANUP
| CHARSET
| COLUMNS
| COMMIT
| COMPACT
| COMPRESSED
| CONSISTENT
| CURRENT
| DATA
| DATE
| DATETIME
| DAY
| DEALLOCATE
| DO
| DUPLICATE
| DYNAMIC
| END
| ENGINE
| ENGINES
| ENUM
| ERRORS
| ESCAPE
| EXECUTE
| FIELDS
| FIRST
| FIXED
| FLUSH
| FOLLOWING
| FORMAT
| FULL
| GLOBAL
| HASH
| HOUR
| LESS
| LOCAL
| LAST
| NAMES
| OFFSET
| PASSWORD %prec lowerThanEq
| PREPARE
| QUICK
| REDUNDANT
| ROLLBACK
| SESSION
| SIGNED
| SNAPSHOT
| START
| STATUS
| SUBPARTITIONS
| SUBPARTITION
| TABLES
| TABLESPACE
| TEXT
| THAN
| TIME %prec lowerThanStringLitToken
| TIMESTAMP %prec lowerThanStringLitToken
| TRACE
| TRANSACTION
| TRUNCATE
| UNBOUNDED
| UNKNOWN
| VALUE
| WARNINGS
| YEAR
| MODE
| WEEK
| ANY
| SOME
| USER
| IDENTIFIED
| COLLATION
| COMMENT
| AVG_ROW_LENGTH
| CONNECTION
| CHECKSUM
| COMPRESSION
| KEY_BLOCK_SIZE
| MASTER
| MAX_ROWS
| MIN_ROWS
| NATIONAL
| ROW_FORMAT
| QUARTER
| GRANTS
| TRIGGERS
| DELAY_KEY_WRITE
| ISOLATION
| JSON
| REPEATABLE
| RESPECT
| COMMITTED
| UNCOMMITTED
| ONLY
| SERIALIZABLE
| LEVEL
| VARIABLES
| SQL_CACHE
| INDEXES
| PROCESSLIST
| SQL_NO_CACHE
| DISABLE
| ENABLE
| REVERSE
| PRIVILEGES
| NO
| BINLOG
| FUNCTION
| VIEW
| BINDING
| BINDINGS
| MODIFY
| EVENTS
| PARTITIONS
| NONE
| NULLS
| SUPER
| EXCLUSIVE
| STATS_PERSISTENT
| ROW_COUNT
| COALESCE
| MONTH
| PROCESS
| PROFILES
| MICROSECOND
| MINUTE
| PLUGINS
| PRECEDING
| QUERY
| QUERIES
| SECOND
| SEPARATOR
| SHARE
| SHARED
| SLOW
| MAX_CONNECTIONS_PER_HOUR
| MAX_QUERIES_PER_HOUR
| MAX_UPDATES_PER_HOUR
| MAX_USER_CONNECTIONS
| REPLICATION
| CLIENT
| SLAVE
| RELOAD
| TEMPORARY
| ROUTINE
| EVENT
| ALGORITHM
| DEFINER
| INVOKER
| MERGE
| TEMPTABLE
| UNDEFINED
| SECURITY
| CASCADED
| RECOVER



TiDBKeyword:
ADMIN
| BUCKETS
| CANCEL
| DDL
| JOBS
| JOB
| STATS
| STATS_META
| STATS_HISTOGRAMS
| STATS_BUCKETS
| STATS_HEALTHY
| TIDB
| TIDB_HJ
| TIDB_SMJ
| TIDB_INLJ
| RESTORE

NotKeywordToken:
 ADDDATE
| BIT_AND
| BIT_OR
| BIT_XOR
| CAST
| COPY
| COUNT
| CURTIME
| DATE_ADD
| DATE_SUB
| EXTRACT
| GET_FORMAT
| GROUP_CONCAT
| INPLACE
| INTERNAL
| MIN
| MAX
| MAX_EXECUTION_TIME
| NOW
| RECENT
| POSITION
| SUBDATE
| SUBSTRING
| SUM
| STD
| STDDEV
| STDDEV_POP
| STDDEV_SAMP
| VARIANCE
| VAR_POP
| VAR_SAMP
| TIMESTAMPADD
| TIMESTAMPDIFF
| TOP
| TRIM
| NEXT_ROW_ID

/************************************************************************************
 *
 *  Insert Statements
 *
 *  TODO: support PARTITION
 **********************************************************************************/
InsertIntoStmt:
	INSERT PriorityOpt IgnoreOptional IntoOpt TableName InsertValues OnDuplicateKeyUpdate
	{
		x := $6.(*ast.InsertStmt)
		x.Priority = $2.(mysql.PriorityEnum)
		x.IgnoreErr = $3.(bool)
		// Wraps many layers here so that it can be processed the same way as select statement.
		ts := &ast.TableSource{Source: $5.(*ast.TableName)}
		x.Table = &ast.TableRefsClause{TableRefs: &ast.Join{Left: ts}}
		if $7 != nil {
			x.OnDuplicate = $7.([]*ast.Assignment)
		}
		$$ = x
	}

IntoOpt:
	{}
|	INTO

InsertValues:
	'(' ColumnNameListOpt ')' ValueSym ValuesList
	{
		$$ = &ast.InsertStmt{
			Columns:   $2.([]*ast.ColumnName),
			Lists:      $5.([][]ast.ExprNode),
		}
	}
|	'(' ColumnNameListOpt ')' SelectStmt
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $4.(*ast.SelectStmt)}
	}
|	'(' ColumnNameListOpt ')' '(' SelectStmt ')'
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $5.(*ast.SelectStmt)}
	}
|	'(' ColumnNameListOpt ')' UnionStmt
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $4.(*ast.UnionStmt)}
	}
|	ValueSym ValuesList %prec insertValues
	{
		$$ = &ast.InsertStmt{Lists:  $2.([][]ast.ExprNode)}
	}
|	'(' SelectStmt ')'
	{
		$$ = &ast.InsertStmt{Select: $2.(*ast.SelectStmt)}
	}
|	SelectStmt
	{
		$$ = &ast.InsertStmt{Select: $1.(*ast.SelectStmt)}
	}
|	UnionStmt
	{
		$$ = &ast.InsertStmt{Select: $1.(*ast.UnionStmt)}
	}
|	SET ColumnSetValueList
	{
		$$ = &ast.InsertStmt{Setlist: $2.([]*ast.Assignment)}
	}

ValueSym:
VALUE
| VALUES

ValuesList:
	RowValue
	{
		$$ = [][]ast.ExprNode{$1.([]ast.ExprNode)}
	}
|	ValuesList ',' RowValue
	{
		$$ = append($1.([][]ast.ExprNode), $3.([]ast.ExprNode))
	}

RowValue:
	'(' ValuesOpt ')'
	{
		$$ = $2
	}

ValuesOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	Values

Values:
	Values ',' ExprOrDefault
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}
|	ExprOrDefault
	{
		$$ = []ast.ExprNode{$1}
	}

ExprOrDefault:
	Expression
|	DEFAULT
	{
		$$ = &ast.DefaultExpr{}
	}

ColumnSetValue:
	ColumnName eq Expression
	{
		$$ = &ast.Assignment{
			Column:	$1.(*ast.ColumnName),
			Expr:	$3,
		}
	}

ColumnSetValueList:
	{
		$$ = []*ast.Assignment{}
	}
|	ColumnSetValue
	{
		$$ = []*ast.Assignment{$1.(*ast.Assignment)}
	}
|	ColumnSetValueList ',' ColumnSetValue
	{
		$$ = append($1.([]*ast.Assignment), $3.(*ast.Assignment))
	}

/*
 * ON DUPLICATE KEY UPDATE col_name=expr [, col_name=expr] ...
 * See https://dev.mysql.com/doc/refman/5.7/en/insert-on-duplicate.html
 */
OnDuplicateKeyUpdate:
	{
		$$ = nil
	}
|	ON DUPLICATE KEY UPDATE AssignmentList
	{
		$$ = $5
	}

/***********************************Insert Statements END************************************/

/************************************************************************************
 *  Replace Statements
 *  See https://dev.mysql.com/doc/refman/5.7/en/replace.html
 *
 *  TODO: support PARTITION
 **********************************************************************************/
ReplaceIntoStmt:
	REPLACE PriorityOpt IntoOpt TableName InsertValues
	{
		x := $5.(*ast.InsertStmt)
		x.IsReplace = true
		x.Priority = $2.(mysql.PriorityEnum)
		ts := &ast.TableSource{Source: $4.(*ast.TableName)}
		x.Table = &ast.TableRefsClause{TableRefs: &ast.Join{Left: ts}}
		$$ = x
	}

/***********************************Replace Statements END************************************/

ODBCDateTimeType:
	d
	{
		$$ = ast.DateLiteral
	}
|	t
	{
		$$ = ast.TimeLiteral
	}
|	ts
	{
		$$ = ast.TimestampLiteral
	}

Literal:
	FALSE
	{
		$$ = ast.NewValueExpr(false)
	}
|	NULL
	{
		$$ = ast.NewValueExpr(nil)
	}
|	TRUE
	{
		$$ = ast.NewValueExpr(true)
	}
|	floatLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	decLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	intLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	StringLiteral %prec lowerThanStringLitToken
	{
		$$ = $1
	}
|	UNDERSCORE_CHARSET stringLit
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/charset-literal.html
		co, err := charset.GetDefaultCollation($1)
		if err != nil {
			yylex.Errorf(Get collation error for charset: %s, $1)
			return 1
		}
		expr := ast.NewValueExpr($2)
		tp := expr.GetType()
		tp.Charset = $1
		tp.Collate = co
		if tp.Collate == charset.CollationBin {
			tp.Flag |= mysql.BinaryFlag
		}
		$$ = expr
	}
|	hexLit
	{
		$$ = ast.NewValueExpr($1)
	}
|	bitLit
	{
		$$ = ast.NewValueExpr($1)
	}

StringLiteral:
	stringLit
	{
		expr := ast.NewValueExpr($1)
		$$ = expr
	}
|	StringLiteral stringLit
	{
		valExpr := $1.(ast.ValueExpr)
		strLit := valExpr.GetString()
		expr := ast.NewValueExpr(strLit+$2)
		// Fix #4239, use first string literal as projection name.
		if valExpr.GetProjectionOffset() >= 0 {
			expr.SetProjectionOffset(valExpr.GetProjectionOffset())
		} else {
			expr.SetProjectionOffset(len(strLit))
		}
		$$ = expr
	}


OrderBy:
	ORDER BY ByList
	{
		$$ = &ast.OrderByClause{Items: $3.([]*ast.ByItem)}
	}

ByList:
	ByItem
	{
		$$ = []*ast.ByItem{$1.(*ast.ByItem)}
	}
|	ByList ',' ByItem
	{
		$$ = append($1.([]*ast.ByItem), $3.(*ast.ByItem))
	}

ByItem:
	Expression Order
	{
		expr := $1
		valueExpr, ok := expr.(ast.ValueExpr)
		if ok {
			position, isPosition := valueExpr.GetValue().(int64)
			if isPosition {
				expr = &ast.PositionExpr{N: int(position)}
			}
		}
		$$ = &ast.ByItem{Expr: expr, Desc: $2.(bool)}
	}

Order:
	/* EMPTY */
	{
		$$ = false // ASC by default
	}
|	ASC
	{
		$$ = false
	}
|	DESC
	{
		$$ = true
	}

OrderByOptional:
	{
		$$ = nil
	}
|	OrderBy
	{
		$$ = $1
	}

BitExpr:
	BitExpr '|' BitExpr %prec '|'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Or, L: $1, R: $3}
	}
|	BitExpr '&' BitExpr %prec '&'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.And, L: $1, R: $3}
	}
|	BitExpr '<<' BitExpr %prec lsh
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LeftShift, L: $1, R: $3}
	}
|	BitExpr '>>' BitExpr %prec rsh
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.RightShift, L: $1, R: $3}
	}
|	BitExpr '+' BitExpr %prec '+'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Plus, L: $1, R: $3}
	}
|	BitExpr '-' BitExpr %prec '-'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Minus, L: $1, R: $3}
	}
|	BitExpr '+' INTERVAL Expression TimeUnit %prec '+'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(DATE_ADD),
			Args: []ast.ExprNode{
				$1,
				$4,
				ast.NewValueExpr($5),
			},
		}
	}
|	BitExpr '-' INTERVAL Expression TimeUnit %prec '+'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(DATE_SUB),
			Args: []ast.ExprNode{
				$1,
				$4,
				ast.NewValueExpr($5),
			},
		}
	}
|	BitExpr '*' BitExpr %prec '*'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mul, L: $1, R: $3}
	}
|	BitExpr '/' BitExpr %prec '/'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Div, L: $1, R: $3}
	}
|	BitExpr '%' BitExpr %prec '%'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $1, R: $3}
	}
|	BitExpr DIV BitExpr %prec div
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.IntDiv, L: $1, R: $3}
	}
|	BitExpr MOD BitExpr %prec mod
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $1, R: $3}
	}
|	BitExpr '^' BitExpr
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Xor, L: $1, R: $3}
	}
|	SimpleExpr

SimpleIdent:
	Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Name: model.NewCIStr($1),
		}}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Table: model.NewCIStr($1),
			Name: model.NewCIStr($3),
		}}
	}
|	'.' Identifier '.' Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Table: model.NewCIStr($2),
			Name: model.NewCIStr($4),
		}}
	}
|	Identifier '.' Identifier '.' Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Schema: model.NewCIStr($1),
			Table: model.NewCIStr($3),
			Name: model.NewCIStr($5),
		}}
	}

SimpleExpr:
	SimpleIdent
|	FunctionCallKeyword
|	FunctionCallNonKeyword
|	FunctionCallGeneric
|	SimpleExpr COLLATE StringName %prec neg
	{
		// TODO: Create a builtin function hold expr and collation. When do evaluation, convert expr result using the collation.
		$$ = $1
	}
|	WindowFuncCall
	{
		$$ = $1.(*ast.WindowFuncExpr)
	}
|	Literal
|	paramMarker
	{
		$$ = ast.NewParamMarkerExpr(yyS[yypt].offset)
	}
|	Variable
|	SumExpr
|	'!' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Not, V: $2}
	}
|	'~'  SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.BitNeg, V: $2}
	}
|	'-' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Minus, V: $2}
	}
|	'+' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Plus, V: $2}
	}
|	SimpleExpr pipes SimpleExpr
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.Concat), Args: []ast.ExprNode{$1, $3}}
	}
|	not2 SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Not, V: $2}
	}
|	SubSelect
|	'(' Expression ')' {
		startOffset := parser.startOffset(&yyS[yypt-1])
		endOffset := parser.endOffset(&yyS[yypt])
		expr := $2
		expr.SetText(parser.src[startOffset:endOffset])
		$$ = &ast.ParenthesesExpr{Expr: expr}
	}
|	'(' ExpressionList ',' Expression ')'
	{
		values := append($2.([]ast.ExprNode), $4)
		$$ = &ast.RowExpr{Values: values}
	}
|	ROW '(' ExpressionList ',' Expression ')'
	{
		values := append($3.([]ast.ExprNode), $5)
		$$ = &ast.RowExpr{Values: values}
	}
|	EXISTS SubSelect
	{
		sq := $2.(*ast.SubqueryExpr)
		sq.Exists = true
		$$ = &ast.ExistsSubqueryExpr{Sel: sq}
	}
|	BINARY SimpleExpr %prec neg
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#operator_binary
		x := types.NewFieldType(mysql.TypeString)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CharsetBin
		$$ = &ast.FuncCastExpr{
			Expr: $2,
			Tp: x,
			FunctionType: ast.CastBinaryOperator,
		}
	}
|	builtinCast '(' Expression AS CastType ')'
 	{
 		/* See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_cast */
 		tp := $5.(*types.FieldType)
 		defaultFlen, defaultDecimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.Tp)
 		if tp.Flen == types.UnspecifiedLength {
 			tp.Flen = defaultFlen
 		}
 		if tp.Decimal == types.UnspecifiedLength {
 			tp.Decimal = defaultDecimal
 		}
 		$$ = &ast.FuncCastExpr{
 			Expr: $3,
 			Tp: tp,
 			FunctionType: ast.CastFunction,
 		}
 	}
|	CASE ExpressionOpt WhenClauseList ElseOpt END
	{
		x := &ast.CaseExpr{WhenClauses: $3.([]*ast.WhenClause)}
		if $2 != nil {
			x.Value = $2
		}
		if $4 != nil {
			x.ElseClause = $4.(ast.ExprNode)
		}
		$$ = x
	}
|	CONVERT '(' Expression ',' CastType ')'
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_convert
		tp := $5.(*types.FieldType)
		defaultFlen, defaultDecimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.Tp)
		if tp.Flen == types.UnspecifiedLength {
			tp.Flen = defaultFlen
		}
		if tp.Decimal == types.UnspecifiedLength {
			tp.Decimal = defaultDecimal
		}
		$$ = &ast.FuncCastExpr{
			Expr: $3,
			Tp: tp,
			FunctionType: ast.CastConvertFunction,
		}
	}
|	CONVERT '(' Expression USING StringName ')'
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_convert
		charset1 := ast.NewValueExpr($5)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3, charset1},
		}
	}
|	DEFAULT '(' SimpleIdent ')'
	{
		$$ = &ast.DefaultExpr{Name: $3.(*ast.ColumnNameExpr).Name}
	}
|	VALUES '(' SimpleIdent ')' %prec lowerThanInsertValues
	{
		$$ = &ast.ValuesExpr{Column: $3.(*ast.ColumnNameExpr)}
	}
|	SimpleIdent jss stringLit
	{
	    expr := ast.NewValueExpr($3)
	    $$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONExtract), Args: []ast.ExprNode{$1, expr}}
	}
|	SimpleIdent juss stringLit
	{
	    expr := ast.NewValueExpr($3)
	    extract := &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONExtract), Args: []ast.ExprNode{$1, expr}}
	    $$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONUnquote), Args: []ast.ExprNode{extract}}
	}

DistinctKwd:
	DISTINCT
|	DISTINCTROW

DistinctOpt:
	ALL
	{
		$$ = false
	}
|	DistinctKwd
	{
		$$ = true
	}

DefaultFalseDistinctOpt:
	{
		$$ = false
	}
|	DistinctOpt

DefaultTrueDistinctOpt:
	{
		$$ = true
	}
|	DistinctOpt

BuggyDefaultFalseDistinctOpt:
	DefaultFalseDistinctOpt
|	DistinctKwd ALL
	{
		$$ = true
	}


FunctionNameConflict:
	ASCII
|	CHARSET
|	COALESCE
|	COLLATION
|	DATE
|	DATABASE
|	DAY
|	HOUR
|	IF
|	INTERVAL %prec lowerThanIntervalKeyword
|	FORMAT
|	LEFT
|	MICROSECOND
|	MINUTE
|	MONTH
|	builtinNow
|	QUARTER
|	REPEAT
|	REPLACE
|	REVERSE
|	RIGHT
|	ROW_COUNT
|	SECOND
|	TIME
|	TIMESTAMP
|	TRUNCATE
|	USER
|	WEEK
|	YEAR

OptionalBraces:
	{}
| '(' ')' {}

FunctionNameOptionalBraces:
	CURRENT_USER
|	CURRENT_DATE
|	UTC_DATE

FunctionNameDatetimePrecision:
	CURRENT_TIME
|	CURRENT_TIMESTAMP
|	LOCALTIME
|	LOCALTIMESTAMP
|	UTC_TIME
|	UTC_TIMESTAMP

FunctionCallKeyword:
	FunctionNameConflict '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	builtinUser '('	ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	FunctionNameOptionalBraces OptionalBraces
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1)}
	}
|	builtinCurDate '(' ')'
    {
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1)}
    }
|	FunctionNameDatetimePrecision FuncDatetimePrec
	{
		args := []ast.ExprNode{}
		if $2 != nil {
			args = append(args, $2.(ast.ExprNode))
		}
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: args}
	}
|	CHAR '(' ExpressionList ')'
	{
		nilVal := ast.NewValueExpr(nil)
		args := $3.([]ast.ExprNode)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.CharFunc),
			Args: append(args, nilVal),
		}
	}
|	CHAR '(' ExpressionList USING StringName ')'
	{
		charset1 := ast.NewValueExpr($5)
		args := $3.([]ast.ExprNode)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.CharFunc),
			Args: append(args, charset1),
		}
	}
|	DATE  stringLit
	{
		expr := ast.NewValueExpr($2)
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.DateLiteral), Args: []ast.ExprNode{expr}}
	}
|	TIME  stringLit
	{
		expr := ast.NewValueExpr($2)
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimeLiteral), Args: []ast.ExprNode{expr}}
	}
|	TIMESTAMP  stringLit
	{
		expr := ast.NewValueExpr($2)
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimestampLiteral), Args: []ast.ExprNode{expr}}
	}
|	INSERT '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName:model.NewCIStr(ast.InsertFunc), Args: $3.([]ast.ExprNode)}
	}
|	MOD '(' BitExpr ',' BitExpr ')'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $3, R: $5}
	}
|	PASSWORD '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName:model.NewCIStr(ast.PasswordFunc), Args: $3.([]ast.ExprNode)}
	}
|	'{' ODBCDateTimeType stringLit '}'
	{
		// This is ODBC syntax for date and time literals.
		// See: https://dev.mysql.com/doc/refman/5.7/en/date-and-time-literals.html
		expr := ast.NewValueExpr($3)
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($2), Args: []ast.ExprNode{expr}}
	}

FunctionCallNonKeyword:
	builtinCurTime '(' FuncDatetimePrecListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	builtinSysDate '(' FuncDatetimePrecListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	FunctionNameDateArithMultiForms '(' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$5,
				ast.NewValueExpr(DAY),
			},
		}
	}
|	FunctionNameDateArithMultiForms '(' Expression ',' INTERVAL Expression TimeUnit ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$6,
				ast.NewValueExpr($7),
			},
		}
	}
|	FunctionNameDateArith '(' Expression ',' INTERVAL Expression TimeUnit ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$6,
				ast.NewValueExpr($7),
			},
		}
	}
|	builtinExtract '(' TimeUnit FROM Expression ')'
	{
		timeUnit := ast.NewValueExpr($3)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{timeUnit, $5},
		}
	}
|	GET_FORMAT '(' GetFormatSelector ','  Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{ast.NewValueExpr($3), $5},
		}
	}
|	builtinPosition '(' BitExpr IN Expression ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: []ast.ExprNode{$3, $5}}
	}
|	builtinSubstring '(' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3, $5},
		}
	}
|	builtinSubstring '(' Expression FROM Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3, $5},
		}
	}
|	builtinSubstring '(' Expression ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3, $5, $7},
		}
	}
|	builtinSubstring '(' Expression FROM Expression FOR Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3, $5, $7},
		}
	}
|	TIMESTAMPADD '(' TimestampUnit ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{ast.NewValueExpr($3), $5, $7},
		}
	}
|	TIMESTAMPDIFF '(' TimestampUnit ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{ast.NewValueExpr($3), $5, $7},
		}
	}
|	builtinTrim '(' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$3},
		}
	}
|	builtinTrim '(' Expression FROM Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$5, $3},
		}
	}
|	builtinTrim '(' TrimDirection FROM Expression ')'
	{
		nilVal := ast.NewValueExpr(nil)
		direction := ast.NewValueExpr(int($3.(ast.TrimDirectionType)))
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$5, nilVal, direction},
		}
	}
|	builtinTrim '(' TrimDirection Expression FROM Expression ')'
	{
		direction := ast.NewValueExpr(int($3.(ast.TrimDirectionType)))
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{$6, $4, direction},
		}
	}

GetFormatSelector:
	DATE
	{
		$$ = strings.ToUpper($1)
	}
| 	DATETIME
	{
		$$ = strings.ToUpper($1)
	}
|	TIME
	{
		$$ = strings.ToUpper($1)
	}
|	TIMESTAMP
	{
		$$ = strings.ToUpper($1)
	}


FunctionNameDateArith:
	builtinDateAdd
|	builtinDateSub


FunctionNameDateArithMultiForms:
	builtinAddDate
|	builtinSubDate


TrimDirection:
	BOTH
	{
		$$ = ast.TrimBoth
	}
|	LEADING
	{
		$$ = ast.TrimLeading
	}
|	TRAILING
	{
		$$ = ast.TrimTrailing
	}

SumExpr:
	AVG '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinBitAnd '(' Expression ')'  OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3},}
		}
	}
|	builtinBitAnd '(' ALL Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4},}
		}
	}
|	builtinBitOr '(' Expression ')'  OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3},}
		}
	}
|	builtinBitOr '(' ALL Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4},}
		}
	}
|	builtinBitXor '(' Expression ')'  OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3},}
		}
	}
|	builtinBitXor '(' ALL Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4},}
		}
	}
|	builtinCount '(' DistinctKwd ExpressionList ')'
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: $4.([]ast.ExprNode), Distinct: true}
	}
|	builtinCount '(' ALL Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4},}
		}
	}
|	builtinCount '(' Expression ')'  OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3},}
		}
	}
|	builtinCount '(' '*' ')'  OptWindowingClause
	{
		args := []ast.ExprNode{ast.NewValueExpr(1)}
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: args, Spec: *($5.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: args,}
		}
	}
|	builtinGroupConcat '(' BuggyDefaultFalseDistinctOpt ExpressionList OrderByOptional OptGConcatSeparator ')'
	{
		args := $4.([]ast.ExprNode)
		args = append(args, $6.(ast.ExprNode))
		$$ = &ast.AggregateFuncExpr{F: $1, Args: args, Distinct: $3.(bool)}
	}
|	builtinMax '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinMin '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinSum '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinStddevPop '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinStddevSamp '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec)),}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinVarPop '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		$$ = &ast.AggregateFuncExpr{F: ast.AggFuncVarPop, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
	}
|	builtinVarSamp '(' BuggyDefaultFalseDistinctOpt Expression ')'  OptWindowingClause
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
	}

OptGConcatSeparator:
        {
            	$$ = ast.NewValueExpr(,)
        }
| SEPARATOR stringLit
	{
		$$ = ast.NewValueExpr($2)
	}


FunctionCallGeneric:
	identifier '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}

FuncDatetimePrec:
	{
		$$ = nil
	}
|	'(' ')'
	{
		$$ = nil
	}
|	'(' intLit ')'
	{
		expr := ast.NewValueExpr($2)
		$$ = expr
	}

TimeUnit:
	MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	SECOND
	{
		$$ = strings.ToUpper($1)
	}
|	MINUTE
	{
		$$ = strings.ToUpper($1)
	}
|	HOUR
	{
		$$ = strings.ToUpper($1)
	}
|	DAY
	{
		$$ = strings.ToUpper($1)
	}
|	WEEK
	{
		$$ = strings.ToUpper($1)
	}
|	MONTH
	{
		$$ = strings.ToUpper($1)
	}
|	QUARTER
	{
		$$ = strings.ToUpper($1)
	}
|	YEAR
	{
		$$ = strings.ToUpper($1)
	}
|	SECOND_MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	MINUTE_MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	MINUTE_SECOND
	{
		$$ = strings.ToUpper($1)
	}
|	HOUR_MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	HOUR_SECOND
	{
		$$ = strings.ToUpper($1)
	}
|	HOUR_MINUTE
	{
		$$ = strings.ToUpper($1)
	}
|	DAY_MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	DAY_SECOND
	{
		$$ = strings.ToUpper($1)
	}
|	DAY_MINUTE
	{
		$$ = strings.ToUpper($1)
	}
|	DAY_HOUR
	{
		$$ = strings.ToUpper($1)
	}
|	YEAR_MONTH
	{
		$$ = strings.ToUpper($1)
	}

TimestampUnit:
	MICROSECOND
	{
		$$ = strings.ToUpper($1)
	}
|	SECOND
	{
		$$ = strings.ToUpper($1)
	}
|	MINUTE
	{
		$$ = strings.ToUpper($1)
	}
|	HOUR
	{
		$$ = strings.ToUpper($1)
	}
|	DAY
	{
		$$ = strings.ToUpper($1)
	}
|	WEEK
	{
		$$ = strings.ToUpper($1)
	}
|	MONTH
	{
		$$ = strings.ToUpper($1)
	}
|	QUARTER
	{
		$$ = strings.ToUpper($1)
	}
|	YEAR
	{
		$$ = strings.ToUpper($1)
	}

ExpressionOpt:
	{
		$$ = nil
	}
|	Expression
	{
		$$ = $1
	}

WhenClauseList:
	WhenClause
	{
		$$ = []*ast.WhenClause{$1.(*ast.WhenClause)}
	}
|	WhenClauseList WhenClause
	{
		$$ = append($1.([]*ast.WhenClause), $2.(*ast.WhenClause))
	}

WhenClause:
	WHEN Expression THEN Expression
	{
		$$ = &ast.WhenClause{
			Expr: $2,
			Result: $4,
		}
	}

ElseOpt:
	/* empty */
	{
		$$ = nil
	}
|	ELSE Expression
	{
		$$ = $2
	}

CastType:
	BINARY OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeVarString)
		x.Flen = $2.(int)  // TODO: Flen should be the flen of expression
		if x.Flen != types.UnspecifiedLength {
			x.Tp = mysql.TypeString
		}
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	CHAR OptFieldLen OptBinary
	{
		x := types.NewFieldType(mysql.TypeVarString)
		x.Flen = $2.(int)  // TODO: Flen should be the flen of expression
		x.Charset = $3.(*ast.OptBinary).Charset
		if $3.(*ast.OptBinary).IsBinary{
			x.Flag |= mysql.BinaryFlag
		}
		if x.Charset ==  {
			x.Charset = mysql.DefaultCharset
			x.Collate = mysql.DefaultCollationName
		}
		$$ = x
	}
|	DATE
	{
		x := types.NewFieldType(mysql.TypeDate)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	DATETIME OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeDatetime)
		x.Flen, _ = mysql.GetDefaultFieldLengthAndDecimalForCast(mysql.TypeDatetime)
		x.Decimal = $2.(int)
		if x.Decimal > 0 {
			x.Flen = x.Flen + 1 + x.Decimal
		}
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	DECIMAL FloatOpt
	{
		fopt := $2.(*ast.FloatOpt)
		x := types.NewFieldType(mysql.TypeNewDecimal)
		x.Flen = fopt.Flen
		x.Decimal = fopt.Decimal
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	TIME OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeDuration)
		x.Flen, _ = mysql.GetDefaultFieldLengthAndDecimalForCast(mysql.TypeDuration)
		x.Decimal = $2.(int)
		if x.Decimal > 0 {
			x.Flen = x.Flen + 1 + x.Decimal
		}
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	SIGNED OptInteger
	{
		x := types.NewFieldType(mysql.TypeLonglong)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	UNSIGNED OptInteger
	{
		x := types.NewFieldType(mysql.TypeLonglong)
		x.Flag |= mysql.UnsignedFlag
| mysql.BinaryFlag
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		$$ = x
	}
|	JSON
	{
		x := types.NewFieldType(mysql.TypeJSON)
		x.Flag |= mysql.BinaryFlag
| (mysql.ParseToJSONFlag)
		x.Charset = mysql.DefaultCharset
		x.Collate = mysql.DefaultCollationName
		$$ = x
	}

PriorityOpt:
	{
		$$ = mysql.NoPriority
	}
|	LOW_PRIORITY
	{
		$$ = mysql.LowPriority
	}
|	HIGH_PRIORITY
	{
		$$ = mysql.HighPriority
	}
|	DELAYED
	{
		$$ = mysql.DelayedPriority
	}

TableName:
	Identifier
	{
		$$ = &ast.TableName{Name:model.NewCIStr($1)}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.TableName{Schema:model.NewCIStr($1),	Name:model.NewCIStr($3)}
	}

TableNameList:
	TableName
	{
		tbl := []*ast.TableName{$1.(*ast.TableName)}
		$$ = tbl
	}
|	TableNameList ',' TableName
	{
		$$ = append($1.([]*ast.TableName), $3.(*ast.TableName))
	}

QuickOptional:
	%prec empty
	{
		$$ = false
	}
|	QUICK
	{
		$$ = true
	}

/***************************Prepared Statement Start******************************
 * See https://dev.mysql.com/doc/refman/5.7/en/prepare.html
 * Example:
 * PREPARE stmt_name FROM 'SELECT SQRT(POW(?,2) + POW(?,2)) AS hypotenuse';
 * OR
 * SET @s = 'SELECT SQRT(POW(?,2) + POW(?,2)) AS hypotenuse';
 * PREPARE stmt_name FROM @s;
 */

PreparedStmt:
	PREPARE Identifier FROM PrepareSQL
	{
		var sqlText string
		var sqlVar *ast.VariableExpr
		switch $4.(type) {
		case string:
			sqlText = $4.(string)
		case *ast.VariableExpr:
			sqlVar = $4.(*ast.VariableExpr)
		}
		$$ = &ast.PrepareStmt{
			Name:		$2,
			SQLText:	sqlText,
			SQLVar: 	sqlVar,
		}
	}

PrepareSQL:
	stringLit
	{
		$$ = $1
	}
|	UserVariable
	{
		$$ = $1.(interface{})
	}


/*
 * See https://dev.mysql.com/doc/refman/5.7/en/execute.html
 * Example:
 * EXECUTE stmt1 USING @a, @b;
 * OR
 * EXECUTE stmt1;
 */
ExecuteStmt:
	EXECUTE Identifier
	{
		$$ = &ast.ExecuteStmt{Name: $2}
	}
|	EXECUTE Identifier USING UserVariableList
	{
		$$ = &ast.ExecuteStmt{
			Name: $2,
			UsingVars: $4.([]ast.ExprNode),
		}
	}

UserVariableList:
	UserVariable
	{
		$$ = []ast.ExprNode{$1}
	}
|	UserVariableList ',' UserVariable
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

/*
 * See https://dev.mysql.com/doc/refman/5.0/en/deallocate-prepare.html
 */

DeallocateStmt:
	DeallocateSym PREPARE Identifier
	{
		$$ = &ast.DeallocateStmt{Name: $3}
	}

DeallocateSym:
DEALLOCATE
| DROP

/****************************Prepared Statement End*******************************/


RollbackStmt:
	ROLLBACK
	{
		$$ = &ast.RollbackStmt{}
	}

SelectStmtBasic:
	SELECT SelectStmtOpts SelectStmtFieldList
	{
		st := &ast.SelectStmt {
			SelectStmtOpts: $2.(*ast.SelectStmtOpts),
			Distinct:      $2.(*ast.SelectStmtOpts).Distinct,
			Fields:        $3.(*ast.FieldList),
		}
		$$ = st
	}

SelectStmtFromDualTable:
	SelectStmtBasic FromDual WhereClauseOptional
	{
		st := $1.(*ast.SelectStmt)
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O ==  {
			lastEnd := yyS[yypt-1].offset-1
			lastField.SetText(parser.src[lastField.Offset:lastEnd])
		}
		if $3 != nil {
			st.Where = $3.(ast.ExprNode)
		}
	}

SelectStmtFromTable:
	SelectStmtBasic FROM
	TableRefsClause WhereClauseOptional SelectStmtGroup HavingClause WindowClauseOptional
	{
		st := $1.(*ast.SelectStmt)
		st.From = $3.(*ast.TableRefsClause)
		if st.SelectStmtOpts.TableHints != nil {
			st.TableHints = st.SelectStmtOpts.TableHints
		}
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O ==  {
			lastEnd := parser.endOffset(&yyS[yypt-5])
			lastField.SetText(parser.src[lastField.Offset:lastEnd])
		}
		if $4 != nil {
			st.Where = $4.(ast.ExprNode)
		}
		if $5 != nil {
			st.GroupBy = $5.(*ast.GroupByClause)
		}
		if $6 != nil {
			st.Having = $6.(*ast.HavingClause)
		}
		if $7 != nil {
		    st.WindowSpecs = ($7.([]ast.WindowSpec))
		}
		$$ = st
	}

SelectStmt:
	SelectStmtBasic OrderByOptional SelectStmtLimit SelectLockOpt
	{
		st := $1.(*ast.SelectStmt)
		st.LockTp = $4.(ast.SelectLockType)
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O ==  {
			src := parser.src
			var lastEnd int
			if $2 != nil {
				lastEnd = yyS[yypt-2].offset-1
			} else if $3 != nil {
				lastEnd = yyS[yypt-1].offset-1
			} else if $4 != ast.SelectLockNone {
				lastEnd = yyS[yypt].offset-1
			} else {
				lastEnd = len(src)
				if src[lastEnd-1] == ';' {
					lastEnd--
				}
			}
			lastField.SetText(src[lastField.Offset:lastEnd])
		}
		if $2 != nil {
			st.OrderBy = $2.(*ast.OrderByClause)
		}
		if $3 != nil {
			st.Limit = $3.(*ast.Limit)
		}
		$$ = st
	}
|	SelectStmtFromDualTable OrderByOptional SelectStmtLimit SelectLockOpt
	{
		st := $1.(*ast.SelectStmt)
		if $2 != nil {
			st.OrderBy = $2.(*ast.OrderByClause)
		}
		if $3 != nil {
			st.Limit = $3.(*ast.Limit)
		}
		st.LockTp = $4.(ast.SelectLockType)
		$$ = st
	}
|	SelectStmtFromTable OrderByOptional SelectStmtLimit SelectLockOpt
	{
		st := $1.(*ast.SelectStmt)
		st.LockTp = $4.(ast.SelectLockType)
		if $2 != nil {
			st.OrderBy = $2.(*ast.OrderByClause)
		}
		if $3 != nil {
			st.Limit = $3.(*ast.Limit)
		}
		$$ = st
	}

FromDual:
	FROM DUAL

WindowClauseOptional:
	{
		$$ = nil
	}
|	WINDOW WindowDefinitionList
	{
		$$ = $2.([]ast.WindowSpec)
	}

WindowDefinitionList:
	WindowDefinition
	{
		$$ = []ast.WindowSpec{$1.(ast.WindowSpec)}
	}
|	WindowDefinitionList ',' WindowDefinition
	{
		$$ = append($1.([]ast.WindowSpec), $3.(ast.WindowSpec))
	}

WindowDefinition:
	WindowName AS WindowSpec
	{
		var spec = $3.(ast.WindowSpec)
		spec.Name = $1.(model.CIStr)
		$$ = spec
	}

WindowName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

WindowSpec:
	'(' WindowSpecDetails ')'
	{
		$$ = $2.(ast.WindowSpec)
	}

WindowSpecDetails:
	OptExistingWindowName OptPartitionClause OptWindowOrderByClause OptWindowFrameClause
	{
		spec := ast.WindowSpec{Ref: $1.(model.CIStr),}
		if $2 != nil {
		    spec.PartitionBy = $2.(*ast.PartitionByClause)
		}
		if $3 != nil {
		    spec.OrderBy = $3.(*ast.OrderByClause)
		}
		if $4 != nil {
		    spec.Frame = $4.(*ast.FrameClause)
		}
		$$ = spec
	}

OptExistingWindowName:
	{
		$$ = model.CIStr{}
	}
|	WindowName
	{
		$$ = $1.(model.CIStr)
	}

OptPartitionClause:
	{
		$$ = nil
	}
|	PARTITION BY ByList
	{
		$$ = &ast.PartitionByClause{Items: $3.([]*ast.ByItem)}
	}

OptWindowOrderByClause:
	{
		$$ = nil
	}
|	ORDER BY ByList
	{
		$$ = &ast.OrderByClause{Items: $3.([]*ast.ByItem)}
	}

OptWindowFrameClause:
	{
		$$ = nil
	}
|	WindowFrameUnits WindowFrameExtent
	{
		$$ = &ast.FrameClause{
			Type: $1.(ast.FrameType),
			Extent: $2.(ast.FrameExtent),
		}
	}

WindowFrameUnits:
	ROWS
	{
		$$ = ast.FrameType(ast.Rows)
	}
|	RANGE
	{
		$$ = ast.FrameType(ast.Ranges)
	}
|	GROUPS
	{
		$$ = ast.FrameType(ast.Groups)
	}

WindowFrameExtent:
	WindowFrameStart
	{
		$$ = ast.FrameExtent {
			Start: $1.(ast.FrameBound),
			End: ast.FrameBound{Type: ast.CurrentRow,},
		}
	}
|	WindowFrameBetween
	{
		$$ = $1.(ast.FrameExtent)
	}

WindowFrameStart:
	UNBOUNDED PRECEDING
	{
		$$ = ast.FrameBound{Type: ast.Preceding, UnBounded: true,}
	}
|	NumLiteral PRECEDING
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: ast.NewValueExpr($1),}
	}
|	paramMarker PRECEDING
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: ast.NewParamMarkerExpr(yyS[yypt].offset),}
	}
|	INTERVAL Expression TimeUnit PRECEDING
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: $2, Unit: ast.NewValueExpr($3),}
	}
|	CURRENT ROW
	{
		$$ = ast.FrameBound{Type: ast.CurrentRow,}
	}

WindowFrameBetween:
	BETWEEN WindowFrameBound AND WindowFrameBound
	{
		$$ = ast.FrameExtent{Start: $2.(ast.FrameBound), End: $4.(ast.FrameBound),}
	}

WindowFrameBound:
	WindowFrameStart
	{
		$$ = $1.(ast.FrameBound)
	}
|	UNBOUNDED FOLLOWING
	{
		$$ = ast.FrameBound{Type: ast.Following, UnBounded: true,}
	}
|	NumLiteral FOLLOWING
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: ast.NewValueExpr($1),}
	}
|	paramMarker FOLLOWING
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: ast.NewParamMarkerExpr(yyS[yypt].offset),}
	}
|	INTERVAL Expression TimeUnit FOLLOWING
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: $2, Unit: ast.NewValueExpr($3),}
	}

OptWindowingClause:
	{
		$$ = nil
	}
|	WindowingClause
	{
		spec := $1.(ast.WindowSpec)
		$$ = &spec
	}

WindowingClause:
	OVER WindowNameOrSpec
	{
		$$ = $2.(ast.WindowSpec)
	}

WindowNameOrSpec:
	WindowName
	{
		$$ = ast.WindowSpec{Ref: $1.(model.CIStr)}
	}
|	WindowSpec
	{
		$$ = $1.(ast.WindowSpec)
	}

WindowFuncCall:
	ROW_NUMBER '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec),}
	}
|	RANK '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec),}
	}
|	DENSE_RANK '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec),}
	}
|	CUME_DIST '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec),}
	}
|	PERCENT_RANK '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec),}
	}
|	NTILE '(' SimpleExpr ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: $5.(ast.WindowSpec),}
	}
|	LEAD '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
	{
		args := []ast.ExprNode{$3}
		if $4 != nil {
			args = append(args, $4.([]ast.ExprNode)...)
		}
		$$ = &ast.WindowFuncExpr{F: $1, Args: args, IgnoreNull: $6.(bool), Spec: $7.(ast.WindowSpec),}
	}
|	LAG '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
	{
		args := []ast.ExprNode{$3}
		if $4 != nil {
			args = append(args, $4.([]ast.ExprNode)...)
		}
		$$ = &ast.WindowFuncExpr{F: $1, Args: args, IgnoreNull: $6.(bool), Spec: $7.(ast.WindowSpec),}
	}
|	FIRST_VALUE '(' Expression ')' OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, IgnoreNull: $5.(bool), Spec: $6.(ast.WindowSpec),}
	}
|	LAST_VALUE '(' Expression ')' OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, IgnoreNull: $5.(bool), Spec: $6.(ast.WindowSpec),}
	}
|	NTH_VALUE '(' Expression ',' SimpleExpr ')' OptFromFirstLast OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3, $5}, FromLast: $7.(bool), IgnoreNull: $8.(bool), Spec: $9.(ast.WindowSpec),}
	}

OptLeadLagInfo:
	{
		$$ = nil
	}
|	',' NumLiteral OptLLDefault
	{
		args := []ast.ExprNode{ast.NewValueExpr($2)}
		if $3 != nil {
			args = append(args, $3.(ast.ExprNode))
		}
		$$ = args
	}
|	',' paramMarker OptLLDefault
	{
		args := []ast.ExprNode{ast.NewValueExpr($2)}
		if $3 != nil {
			args = append(args, $3.(ast.ExprNode))
		}
		$$ = args
	}

OptLLDefault:
	{
		$$ = nil
	}
|	',' Expression
	{
		$$ = $2
	}

OptNullTreatment:
	{
		$$ = false
	}
|	RESPECT NULLS
	{
		$$ = false
	}
|	IGNORE NULLS
	{
		$$ = true
	}

OptFromFirstLast:
	{
		$$ = false
	}
|	FROM FIRST
	{
		$$ = false
	}
|	FROM LAST
	{
		$$ = true
	}

TableRefsClause:
	TableRefs
	{
		$$ = &ast.TableRefsClause{TableRefs: $1.(*ast.Join)}
	}

TableRefs:
	EscapedTableRef
	{
		if j, ok := $1.(*ast.Join); ok {
			// if $1 is Join, use it directly
			$$ = j
		} else {
			$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: nil}
		}
	}
|	TableRefs ',' EscapedTableRef
	{
		/* from a, b is default cross join */
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin}
	}

EscapedTableRef:
	TableRef %prec lowerThanSetKeyword
	{
		$$ = $1
	}
|	'{' Identifier TableRef '}'
	{
		/*
		* ODBC escape syntax for outer join is { OJ join_table }
		* Use an Identifier for OJ
		*/
		$$ = $3
	}

TableRef:
	TableFactor
	{
		$$ = $1
	}
|	JoinTable
	{
		$$ = $1
	}

TableFactor:
	TableName PartitionNameListOpt TableAsNameOpt IndexHintListOpt
	{
		tn := $1.(*ast.TableName)
		tn.PartitionNames = $2.([]model.CIStr)
		tn.IndexHints = $4.([]*ast.IndexHint)
		$$ = &ast.TableSource{Source: tn, AsName: $3.(model.CIStr)}
	}
|	'(' SelectStmt ')' TableAsName
	{
		st := $2.(*ast.SelectStmt)
		endOffset := parser.endOffset(&yyS[yypt-1])
		parser.setLastSelectFieldText(st, endOffset)
		$$ = &ast.TableSource{Source: $2.(*ast.SelectStmt), AsName: $4.(model.CIStr)}
	}
|	'(' UnionStmt ')' TableAsName
	{
		$$ = &ast.TableSource{Source: $2.(*ast.UnionStmt), AsName: $4.(model.CIStr)}
	}
|	'(' TableRefs ')'
	{
		$$ = $2
	}

PartitionNameListOpt:
    /* empty */
    {
        $$ = []model.CIStr{}
    }
|    PARTITION '(' PartitionNameList ')'
    {
        $$ = $3
    }

TableAsNameOpt:
	{
		$$ = model.CIStr{}
	}
|	TableAsName
	{
		$$ = $1
	}

TableAsName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}
|	AS Identifier
	{
		$$ = model.NewCIStr($2)
	}

IndexHintType:
	USE KeyOrIndex
	{
		$$ = ast.HintUse
	}
|	IGNORE KeyOrIndex
	{
		$$ = ast.HintIgnore
	}
|	FORCE KeyOrIndex
	{
		$$ = ast.HintForce
	}

IndexHintScope:
	{
		$$ = ast.HintForScan
	}
|	FOR JOIN
	{
		$$ = ast.HintForJoin
	}
|	FOR ORDER BY
	{
		$$ = ast.HintForOrderBy
	}
|	FOR GROUP BY
	{
		$$ = ast.HintForGroupBy
	}


IndexHint:
	IndexHintType IndexHintScope '(' IndexNameList ')'
	{
		$$ = &ast.IndexHint{
			IndexNames:	$4.([]model.CIStr),
			HintType:	$1.(ast.IndexHintType),
			HintScope:	$2.(ast.IndexHintScope),
		}
	}

IndexNameList:
	{
		var nameList []model.CIStr
		$$ = nameList
	}
|	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	IndexNameList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}
|	PRIMARY
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}

IndexHintList:
	IndexHint
	{
		$$ = []*ast.IndexHint{$1.(*ast.IndexHint)}
	}
|	IndexHintList IndexHint
 	{
 		$$ = append($1.([]*ast.IndexHint), $2.(*ast.IndexHint))
 	}

IndexHintListOpt:
	{
		var hintList []*ast.IndexHint
		$$ = hintList
	}
|	IndexHintList
	{
		$$ = $1
	}

JoinTable:
	/* Use %prec to evaluate production TableRef before cross join */
	TableRef CrossOpt TableRef %prec tableRefPriority
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin}
	}
|	TableRef CrossOpt TableRef ON Expression
	{
		on := &ast.OnCondition{Expr: $5}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin, On: on}
	}
|	TableRef CrossOpt TableRef USING '(' ColumnNameList ')'
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin, Using: $6.([]*ast.ColumnName)}
	}
|	TableRef JoinType OuterOpt JOIN TableRef ON Expression
	{
		on := &ast.OnCondition{Expr: $7}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $5.(ast.ResultSetNode), Tp: $2.(ast.JoinType), On: on}
	}
|	TableRef JoinType OuterOpt JOIN TableRef USING '(' ColumnNameList ')'
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $5.(ast.ResultSetNode), Tp: $2.(ast.JoinType), Using: $8.([]*ast.ColumnName)}
	}
|	TableRef NATURAL JOIN TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $4.(ast.ResultSetNode), NaturalJoin: true}
	}
|	TableRef NATURAL JoinType OuterOpt JOIN TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $6.(ast.ResultSetNode), Tp: $3.(ast.JoinType), NaturalJoin: true}
	}
|	TableRef STRAIGHT_JOIN TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), StraightJoin: true}
	}
|	TableRef STRAIGHT_JOIN TableRef ON Expression
	{
		on := &ast.OnCondition{Expr: $5}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), StraightJoin: true, On: on}
	}

JoinType:
	LEFT
	{
		$$ = ast.LeftJoin
	}
|	RIGHT
	{
		$$ = ast.RightJoin
	}

OuterOpt:
	{}
|	OUTER

CrossOpt:
	JOIN
|	CROSS JOIN
|	INNER JOIN


LimitClause:
	{
		$$ = nil
	}
|	LIMIT LimitOption
	{
		$$ = &ast.Limit{Count: $2.(ast.ValueExpr)}
	}

LimitOption:
	LengthNum
	{
		$$ = ast.NewValueExpr($1)
	}
|	paramMarker
	{
		$$ = ast.NewParamMarkerExpr(yyS[yypt].offset)
	}

SelectStmtLimit:
	{
		$$ = nil
	}
|	LIMIT LimitOption
	{
		$$ = &ast.Limit{Count: $2.(ast.ExprNode)}
	}
|	LIMIT LimitOption ',' LimitOption
	{
		$$ = &ast.Limit{Offset: $2.(ast.ExprNode), Count: $4.(ast.ExprNode)}
	}
|	LIMIT LimitOption OFFSET LimitOption
	{
		$$ = &ast.Limit{Offset: $4.(ast.ExprNode), Count: $2.(ast.ExprNode)}
	}


SelectStmtOpts:
	TableOptimizerHints DefaultFalseDistinctOpt PriorityOpt SelectStmtSQLCache SelectStmtCalcFoundRows SelectStmtStraightJoin
	{
		opt := &ast.SelectStmtOpts{}
		if $1 != nil {
			opt.TableHints = $1.([]*ast.TableOptimizerHint)
		}
		if $2 != nil {
			opt.Distinct = $2.(bool)
		}
		if $3 != nil {
			opt.Priority = $3.(mysql.PriorityEnum)
		}
		if $4 != nil {
			opt.SQLCache = $4.(bool)
		}
		if $5 != nil {
			opt.CalcFoundRows = $5.(bool)
		}
		if $6 != nil {
			opt.StraightJoin = $6.(bool)
		}

		$$ = opt
	}

TableOptimizerHints:
	/* empty */
	{
		$$ = nil
	}
|	hintBegin TableOptimizerHintList hintEnd
	{
		$$ = $2
	}
|	hintBegin error hintEnd
	{
		yyerrok()
		parser.lastErrorAsWarn()
		$$ = nil
	}

HintTableList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	HintTableList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

TableOptimizerHintList:
	TableOptimizerHintOpt
	{
		$$ = []*ast.TableOptimizerHint{$1.(*ast.TableOptimizerHint)}
	}
|	TableOptimizerHintList TableOptimizerHintOpt
	{
		$$ = append($1.([]*ast.TableOptimizerHint), $2.(*ast.TableOptimizerHint))
	}

TableOptimizerHintOpt:
	tidbSMJ '(' HintTableList ')'
	{
		$$ = &ast.TableOptimizerHint{HintName: model.NewCIStr($1), Tables: $3.([]model.CIStr)}
	}
|	tidbINLJ '(' HintTableList ')'
	{
		$$ = &ast.TableOptimizerHint{HintName: model.NewCIStr($1), Tables: $3.([]model.CIStr)}
	}
|	tidbHJ '(' HintTableList ')'
	{
		$$ = &ast.TableOptimizerHint{HintName: model.NewCIStr($1), Tables: $3.([]model.CIStr)}
	}
|	maxExecutionTime '(' NUM ')'
	{
		$$ = &ast.TableOptimizerHint{HintName: model.NewCIStr($1), MaxExecutionTime: getUint64FromNUM($3)}
	}

SelectStmtCalcFoundRows:
	{
		$$ = false
	}
|	SQL_CALC_FOUND_ROWS
	{
		$$ = true
	}
SelectStmtSQLCache:
	%prec empty
	{
		$$ = true
	}
|	SQL_CACHE
	{
		$$ = true
	}
|	SQL_NO_CACHE
	{
		$$ = false
	}
SelectStmtStraightJoin:
	%prec empty
	{
		$$ = false
	}
|	STRAIGHT_JOIN
	{
		$$ = true
	}

SelectStmtFieldList:
	FieldList
	{
		$$ = &ast.FieldList{Fields: $1.([]*ast.SelectField)}
	}

SelectStmtGroup:
	/* EMPTY */
	{
		$$ = nil
	}
|	GroupByClause

// See https://dev.mysql.com/doc/refman/5.7/en/subqueries.html
SubSelect:
	'(' SelectStmt ')'
	{
		s := $2.(*ast.SelectStmt)
		endOffset := parser.endOffset(&yyS[yypt])
		parser.setLastSelectFieldText(s, endOffset)
		src := parser.src
		// See the implementation of yyParse function
		s.SetText(src[yyS[yypt-1].offset:yyS[yypt].offset])
		$$ = &ast.SubqueryExpr{Query: s}
	}
|	'(' UnionStmt ')'
	{
		s := $2.(*ast.UnionStmt)
		src := parser.src
		// See the implementation of yyParse function
		s.SetText(src[yyS[yypt-1].offset:yyS[yypt].offset])
		$$ = &ast.SubqueryExpr{Query: s}
	}

// See https://dev.mysql.com/doc/refman/5.7/en/innodb-locking-reads.html
SelectLockOpt:
	/* empty */
	{
		$$ = ast.SelectLockNone
	}
|	FOR UPDATE
	{
		$$ = ast.SelectLockForUpdate
	}
|	LOCK IN SHARE MODE
	{
		$$ = ast.SelectLockInShareMode
	}

// See https://dev.mysql.com/doc/refman/5.7/en/union.html
UnionStmt:
	UnionClauseList UNION UnionOpt SelectStmtBasic OrderByOptional SelectStmtLimit SelectLockOpt
	{
		st := $4.(*ast.SelectStmt)
		union := $1.(*ast.UnionStmt)
		st.IsAfterUnionDistinct = $3.(bool)
		lastSelect := union.SelectList.Selects[len(union.SelectList.Selects)-1]
		endOffset := parser.endOffset(&yyS[yypt-5])
		parser.setLastSelectFieldText(lastSelect, endOffset)
		union.SelectList.Selects = append(union.SelectList.Selects, st)
		if $5 != nil {
		    union.OrderBy = $5.(*ast.OrderByClause)
		}
		if $6 != nil {
		    union.Limit = $6.(*ast.Limit)
		}
		if $5 == nil && $6 == nil {
		    st.LockTp = $7.(ast.SelectLockType)
		}
		$$ = union
	}
|	UnionClauseList UNION UnionOpt SelectStmtFromDualTable OrderByOptional
    SelectStmtLimit SelectLockOpt
	{
		st := $4.(*ast.SelectStmt)
		union := $1.(*ast.UnionStmt)
		st.IsAfterUnionDistinct = $3.(bool)
		lastSelect := union.SelectList.Selects[len(union.SelectList.Selects)-1]
		endOffset := parser.endOffset(&yyS[yypt-5])
		parser.setLastSelectFieldText(lastSelect, endOffset)
		union.SelectList.Selects = append(union.SelectList.Selects, st)
		if $5 != nil {
			union.OrderBy = $5.(*ast.OrderByClause)
		}
		if $6 != nil {
			union.Limit = $6.(*ast.Limit)
		}
		if $5 == nil && $6 == nil {
			st.LockTp = $7.(ast.SelectLockType)
		}
		$$ = union
	}
|	UnionClauseList UNION UnionOpt SelectStmtFromTable OrderByOptional
   	SelectStmtLimit SelectLockOpt
	{
		st := $4.(*ast.SelectStmt)
		union := $1.(*ast.UnionStmt)
		st.IsAfterUnionDistinct = $3.(bool)
		lastSelect := union.SelectList.Selects[len(union.SelectList.Selects)-1]
		endOffset := parser.endOffset(&yyS[yypt-5])
		parser.setLastSelectFieldText(lastSelect, endOffset)
		union.SelectList.Selects = append(union.SelectList.Selects, st)
		if $5 != nil {
			union.OrderBy = $5.(*ast.OrderByClause)
		}
		if $6 != nil {
			union.Limit = $6.(*ast.Limit)
		}
		if $5 == nil && $6 == nil {
			st.LockTp = $7.(ast.SelectLockType)
		}
		$$ = union
	}
|	UnionClauseList UNION UnionOpt '(' SelectStmt ')' OrderByOptional SelectStmtLimit
	{
		union := $1.(*ast.UnionStmt)
		lastSelect := union.SelectList.Selects[len(union.SelectList.Selects)-1]
		endOffset := parser.endOffset(&yyS[yypt-6])
		parser.setLastSelectFieldText(lastSelect, endOffset)
		st := $5.(*ast.SelectStmt)
		st.IsInBraces = true
		st.IsAfterUnionDistinct = $3.(bool)
		endOffset = parser.endOffset(&yyS[yypt-2])
		parser.setLastSelectFieldText(st, endOffset)
		union.SelectList.Selects = append(union.SelectList.Selects, st)
		if $7 != nil {
			union.OrderBy = $7.(*ast.OrderByClause)
		}
		if $8 != nil {
			union.Limit = $8.(*ast.Limit)
		}
		$$ = union
	}

UnionClauseList:
	UnionSelect
	{
		selectList := &ast.UnionSelectList{Selects: []*ast.SelectStmt{$1.(*ast.SelectStmt)}}
		$$ = &ast.UnionStmt{
			SelectList: selectList,
		}
	}
|	UnionClauseList UNION UnionOpt UnionSelect
	{
		union := $1.(*ast.UnionStmt)
		st := $4.(*ast.SelectStmt)
		st.IsAfterUnionDistinct = $3.(bool)
		lastSelect := union.SelectList.Selects[len(union.SelectList.Selects)-1]
		endOffset := parser.endOffset(&yyS[yypt-2])
		parser.setLastSelectFieldText(lastSelect, endOffset)
		union.SelectList.Selects = append(union.SelectList.Selects, st)
		$$ = union
	}

UnionSelect:
	SelectStmt
	{
		$$ = $1.(interface{})
	}
|	'(' SelectStmt ')'
	{
		st := $2.(*ast.SelectStmt)
		st.IsInBraces = true
		endOffset := parser.endOffset(&yyS[yypt])
		parser.setLastSelectFieldText(st, endOffset)
		$$ = $2
	}

UnionOpt:
DefaultTrueDistinctOpt


/********************Set Statement*******************************/
SetStmt:
	SET VariableAssignmentList
	{
		$$ = &ast.SetStmt{Variables: $2.([]*ast.VariableAssignment)}
	}
|	SET PASSWORD eq PasswordOpt
	{
		$$ = &ast.SetPwdStmt{Password: $4.(string)}
	}
|	SET PASSWORD FOR Username eq PasswordOpt
	{
		$$ = &ast.SetPwdStmt{User: $4.(*auth.UserIdentity), Password: $6.(string)}
	}
|	SET GLOBAL TRANSACTION TransactionChars
	{
		vars := $4.([]*ast.VariableAssignment)
		for _, v := range vars {
			v.IsGlobal = true
		}
		$$ = &ast.SetStmt{Variables: vars}
	}
|	SET SESSION TRANSACTION TransactionChars
	{
		$$ = &ast.SetStmt{Variables: $4.([]*ast.VariableAssignment)}
	}
|	SET TRANSACTION TransactionChars
	{
		assigns := $3.([]*ast.VariableAssignment)
		for i:=0; i<len(assigns); i++ {
			if assigns[i].Name == tx_isolation {
				// A special session variable that make setting tx_isolation take effect one time.
				assigns[i].Name = tx_isolation_one_shot
			}
		}
		$$ = &ast.SetStmt{Variables: assigns}
	}

TransactionChars:
	TransactionChar
	{
		if $1 != nil {
			$$ = $1
		} else {
			$$ = []*ast.VariableAssignment{}
		}
	}
|	TransactionChars ',' TransactionChar
	{
		if $3 != nil {
			varAssigns := $3.([]*ast.VariableAssignment)
			$$ = append($1.([]*ast.VariableAssignment), varAssigns...)
		} else {
			$$ = $1
		}
	}

TransactionChar:
	ISOLATION LEVEL IsolationLevel
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr($3)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: tx_isolation, Value: expr, IsSystem: true})
		$$ = varAssigns
	}
|	READ WRITE
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr(0)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: tx_read_only, Value: expr, IsSystem: true})
		$$ = varAssigns
	}
|	READ ONLY
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr(1)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: tx_read_only, Value: expr, IsSystem: true})
		$$ = varAssigns
	}

IsolationLevel:
	REPEATABLE READ
	{
		$$ = ast.RepeatableRead
	}
|	READ	COMMITTED
	{
		$$ = ast.ReadCommitted
	}
|	READ	UNCOMMITTED
	{
		$$ = ast.ReadUncommitted
	}
|	SERIALIZABLE
	{
		$$ = ast.Serializable
	}

SetExpr:
	ON
	{
		$$ = ast.NewValueExpr(ON)
	}
|	ExprOrDefault

VariableAssignment:
	Identifier eq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $1, Value: $3, IsSystem: true}
	}
|	GLOBAL Identifier eq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsGlobal: true, IsSystem: true}
	}
|	SESSION Identifier eq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsSystem: true}
	}
|	LOCAL Identifier eq Expression
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsSystem: true}
	}
|	doubleAtIdentifier eq SetExpr
	{
		v := strings.ToLower($1)
		var isGlobal bool
		if strings.HasPrefix(v, @@global.) {
			isGlobal = true
			v = strings.TrimPrefix(v, @@global.)
		} else if strings.HasPrefix(v, @@session.) {
			v = strings.TrimPrefix(v, @@session.)
		} else if strings.HasPrefix(v, @@local.) {
			v = strings.TrimPrefix(v, @@local.)
		} else if strings.HasPrefix(v, @@) {
			v = strings.TrimPrefix(v, @@)
		}
		$$ = &ast.VariableAssignment{Name: v, Value: $3, IsGlobal: isGlobal, IsSystem: true}
	}
|	singleAtIdentifier eq Expression
	{
		v := $1
		v = strings.TrimPrefix(v, @)
		$$ = &ast.VariableAssignment{Name: v, Value: $3}
	}
|	singleAtIdentifier assignmentEq Expression
	{
		v := $1
		v = strings.TrimPrefix(v, @)
		$$ = &ast.VariableAssignment{Name: v, Value: $3}
	}
|	NAMES CharsetName
	{
		$$ = &ast.VariableAssignment{
			Name: ast.SetNames,
			Value: ast.NewValueExpr($2.(string)),
		}
	}
|	NAMES CharsetName COLLATE DEFAULT
	{
		$$ = &ast.VariableAssignment{
			Name: ast.SetNames,
			Value: ast.NewValueExpr($2.(string)),
		}
	}
|	NAMES CharsetName COLLATE StringName
	{
		$$ = &ast.VariableAssignment{
			Name: ast.SetNames,
			Value: ast.NewValueExpr($2.(string)),
			ExtendValue: ast.NewValueExpr($4.(string)),
		}
	}
|	CharsetKw CharsetName
	{
		$$ = &ast.VariableAssignment{
			Name: ast.SetNames,
			Value: ast.NewValueExpr($2.(string)),
		}
	}

CharsetName:
	StringName
	{
		$$ = $1
	}
|	binaryType
	{
		$$ = charset.CharsetBin
	}

VariableAssignmentList:
	{
		$$ = []*ast.VariableAssignment{}
	}
|	VariableAssignment
	{
		$$ = []*ast.VariableAssignment{$1.(*ast.VariableAssignment)}
	}
|	VariableAssignmentList ',' VariableAssignment
	{
		$$ = append($1.([]*ast.VariableAssignment), $3.(*ast.VariableAssignment))
	}

Variable:
	SystemVariable
| UserVariable

SystemVariable:
	doubleAtIdentifier
	{
		v := strings.ToLower($1)
		var isGlobal bool
		explicitScope := true
		if strings.HasPrefix(v, @@global.) {
			isGlobal = true
			v = strings.TrimPrefix(v, @@global.)
		} else if strings.HasPrefix(v, @@session.) {
			v = strings.TrimPrefix(v, @@session.)
		} else if strings.HasPrefix(v, @@local.) {
			v = strings.TrimPrefix(v, @@local.)
		} else if strings.HasPrefix(v, @@) {
			v, explicitScope = strings.TrimPrefix(v, @@), false
		}
		$$ = &ast.VariableExpr{Name: v, IsGlobal: isGlobal, IsSystem: true, ExplicitScope: explicitScope}
	}

UserVariable:
	singleAtIdentifier
	{
		v := $1
		v = strings.TrimPrefix(v, @)
		$$ = &ast.VariableExpr{Name: v, IsGlobal: false, IsSystem: false}
	}

Username:
	StringName
	{
		$$ = &auth.UserIdentity{Username: $1.(string), Hostname: %}
	}
|	StringName '@' StringName
	{
		$$ = &auth.UserIdentity{Username: $1.(string), Hostname: $3.(string)}
	}
|	StringName singleAtIdentifier
	{
		$$ = &auth.UserIdentity{Username: $1.(string), Hostname: strings.TrimPrefix($2, @)}
	}
|	CURRENT_USER OptionalBraces
	{
		$$ = &auth.UserIdentity{CurrentUser: true}
	}

UsernameList:
	Username
	{
		$$ = []*auth.UserIdentity{$1.(*auth.UserIdentity)}
	}
|	UsernameList ',' Username
	{
		$$ = append($1.([]*auth.UserIdentity), $3.(*auth.UserIdentity))
	}

PasswordOpt:
	stringLit
	{
		$$ = $1
	}
|	PASSWORD '(' AuthString ')'
	{
		$$ = $3.(string)
	}

AuthString:
	stringLit
	{
		$$ = $1
	}

/****************************Admin Statement*******************************/
AdminStmt:
	ADMIN SHOW DDL
	{
		$$ = &ast.AdminStmt{Tp: ast.AdminShowDDL}
	}
|	ADMIN SHOW DDL JOBS
	{
		$$ = &ast.AdminStmt{Tp: ast.AdminShowDDLJobs}
	}
|	ADMIN SHOW DDL JOBS NUM
	{
		$$ = &ast.AdminStmt{
		    Tp: ast.AdminShowDDLJobs,
		    JobNumber: $5.(int64),
		}
	}
|	ADMIN SHOW TableName NEXT_ROW_ID
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminShowNextRowID,
			Tables: []*ast.TableName{$3.(*ast.TableName)},
		}
	}
|	ADMIN CHECK TABLE TableNameList
	{
		$$ = &ast.AdminStmt{
			Tp:	ast.AdminCheckTable,
			Tables: $4.([]*ast.TableName),
		}
	}
|	ADMIN CHECK INDEX TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminCheckIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index: string($5),
		}
	}
|	ADMIN RECOVER INDEX TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminRecoverIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index: string($5),
		}
	}
|	ADMIN RESTORE TABLE BY JOB NUM
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminRestoreTable,
			JobIDs: []int64{$6.(int64)},
		}
	}
|	ADMIN RESTORE TABLE TableName
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminRestoreTable,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
		}
	}
|	ADMIN RESTORE TABLE TableName NUM
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminRestoreTable,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
		        JobNumber: $5.(int64),
		}
	}
|	ADMIN CLEANUP INDEX TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminCleanupIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index: string($5),
		}
	}
|	ADMIN CHECK INDEX TableName Identifier HandleRangeList
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminCheckIndexRange,
			Tables:	[]*ast.TableName{$4.(*ast.TableName)},
			Index: string($5),
			HandleRanges: $6.([]ast.HandleRange),
		}
	}
|	ADMIN CHECKSUM TABLE TableNameList
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminChecksumTable,
			Tables: $4.([]*ast.TableName),
		}
	}
|	ADMIN CANCEL DDL JOBS NumList
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminCancelDDLJobs,
			JobIDs: $5.([]int64),
		}
	}
|	ADMIN SHOW DDL JOB QUERIES NumList
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminShowDDLJobQueries,
			JobIDs: $6.([]int64),
		}
	}
|	ADMIN SHOW SLOW AdminShowSlow
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminShowSlow,
			ShowSlow: $4.(*ast.ShowSlow),
		}
	}

AdminShowSlow:
	RECENT NUM
	{
		$$ = &ast.ShowSlow{
			Tp: ast.ShowSlowRecent,
			Count: getUint64FromNUM($2),
		}
	}
|	TOP NUM
	{
		$$ = &ast.ShowSlow{
			Tp: ast.ShowSlowTop,
			Kind: ast.ShowSlowKindDefault,
			Count: getUint64FromNUM($2),
		}
	}
|	TOP INTERNAL NUM
	{
		$$ = &ast.ShowSlow{
			Tp: ast.ShowSlowTop,
			Kind: ast.ShowSlowKindInternal,
			Count: getUint64FromNUM($3),
		}
	}
|	TOP ALL NUM
	{
		$$ = &ast.ShowSlow{
			Tp: ast.ShowSlowTop,
			Kind: ast.ShowSlowKindAll,
			Count: getUint64FromNUM($3),
		}
	}

HandleRangeList:
	HandleRange
	{
		$$ = []ast.HandleRange{$1.(ast.HandleRange)}
	}
|	HandleRangeList ',' HandleRange
	{
		$$ = append($1.([]ast.HandleRange), $3.(ast.HandleRange))
	}

HandleRange:
	'(' NUM ',' NUM ')'
	{
		$$ = ast.HandleRange{Begin: $2.(int64), End: $4.(int64)}
	}


NumList:
       NUM
       {
	        $$ = []int64{$1.(int64)}
       }
|
       NumList ',' NUM
       {
	        $$ = append($1.([]int64), $3.(int64))
       }

/****************************Show Statement*******************************/
ShowStmt:
	SHOW ShowTargetFilterable ShowLikeOrWhereOpt
	{
		stmt := $2.(*ast.ShowStmt)
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	SHOW CREATE TABLE TableName
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowCreateTable,
			Table:	$4.(*ast.TableName),
		}
	}
|	SHOW CREATE VIEW TableName
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowCreateView,
			Table:	$4.(*ast.TableName),
		}
	}
|	SHOW CREATE DATABASE IfNotExists DBName
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowCreateDatabase,
			IfNotExists: $4.(bool),
			DBName:	$5.(string),
		}
	}
|	SHOW CREATE USER Username
        {
                // See https://dev.mysql.com/doc/refman/5.7/en/show-create-user.html
                $$ = &ast.ShowStmt{
                        Tp:	ast.ShowCreateUser,
                        User:	$4.(*auth.UserIdentity),
                }
        }
|	SHOW GRANTS
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/show-grants.html
		$$ = &ast.ShowStmt{Tp: ast.ShowGrants}
	}
|	SHOW GRANTS FOR Username
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/show-grants.html
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowGrants,
			User:	$4.(*auth.UserIdentity),
		}
	}
|	SHOW MASTER STATUS
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowMasterStatus,
		}
	}
|	SHOW OptFull PROCESSLIST
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowProcessList,
			Full:	$2.(bool),
		}
	}
|	SHOW STATS_META ShowLikeOrWhereOpt
	{
		stmt := &ast.ShowStmt{
			Tp: ast.ShowStatsMeta,
		}
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	SHOW STATS_HISTOGRAMS ShowLikeOrWhereOpt
	{
		stmt := &ast.ShowStmt{
			Tp: ast.ShowStatsHistograms,
		}
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	SHOW STATS_BUCKETS ShowLikeOrWhereOpt
	{
		stmt := &ast.ShowStmt{
			Tp: ast.ShowStatsBuckets,
		}
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	SHOW STATS_HEALTHY ShowLikeOrWhereOpt
	{
		stmt := &ast.ShowStmt{
			Tp: ast.ShowStatsHealthy,
		}
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	SHOW PROFILES
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowProfiles,
		}
	}
|	SHOW PRIVILEGES
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowPrivileges,
		}
	}

ShowIndexKwd:
	INDEX
|	INDEXES
|	KEYS

FromOrIn:
FROM
| IN

ShowTargetFilterable:
	ENGINES
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowEngines}
	}
|	DATABASES
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowDatabases}
	}
|	CharsetKw
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowCharset}
	}
|	OptFull TABLES ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowTables,
			DBName:	$3.(string),
			Full:	$1.(bool),
		}
	}
|	TABLE STATUS ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowTableStatus,
			DBName:	$3.(string),
		}
	}
|	ShowIndexKwd FromOrIn TableName
	{
        $$ = &ast.ShowStmt{
            Tp: ast.ShowIndex,
            Table: $3.(*ast.TableName),
		}
	}
|	ShowIndexKwd FromOrIn Identifier FromOrIn Identifier
	{
        show := &ast.ShowStmt{
            Tp: ast.ShowIndex,
            Table: &ast.TableName{Name:model.NewCIStr($3), Schema: model.NewCIStr($5)},
		}
        $$ = show
	}
|	OptFull COLUMNS ShowTableAliasOpt ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowColumns,
			Table:	$3.(*ast.TableName),
			DBName:	$4.(string),
			Full:	$1.(bool),
		}
	}
|	OptFull FIELDS ShowTableAliasOpt ShowDatabaseNameOpt
	{
		// SHOW FIELDS is a synonym for SHOW COLUMNS.
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowColumns,
			Table:	$3.(*ast.TableName),
			DBName:	$4.(string),
			Full:	$1.(bool),
		}
	}
|	WARNINGS
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowWarnings}
	}
|	ERRORS
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowErrors}
	}
|	GlobalScope VARIABLES
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowVariables,
			GlobalScope: $1.(bool),
		}
	}
|	GlobalScope STATUS
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowStatus,
			GlobalScope: $1.(bool),
		}
	}
|	GlobalScope BINDINGS
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowBindings,
			GlobalScope: $1.(bool),
		}
	}
|	COLLATION
	{
		$$ = &ast.ShowStmt{
			Tp: 	ast.ShowCollation,
		}
	}
|	TRIGGERS ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowTriggers,
			DBName:	$2.(string),
		}
	}
|	PROCEDURE STATUS
	{
		$$ = &ast.ShowStmt {
			Tp: ast.ShowProcedureStatus,
		}
	}
|	FUNCTION STATUS
	{
		// This statement is similar to SHOW PROCEDURE STATUS but for stored functions.
		// See http://dev.mysql.com/doc/refman/5.7/en/show-function-status.html
		// We do not support neither stored functions nor stored procedures.
		// So we reuse show procedure status process logic.
		$$ = &ast.ShowStmt {
			Tp: ast.ShowProcedureStatus,
		}
	}
|	EVENTS ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:	ast.ShowEvents,
			DBName:	$2.(string),
		}
	}
|	PLUGINS
	{
		$$ = &ast.ShowStmt{
			Tp: 	ast.ShowPlugins,
		}
	}
ShowLikeOrWhereOpt:
	{
		$$ = nil
	}
|	LIKE SimpleExpr
	{
		$$ = &ast.PatternLikeExpr{
			Pattern: $2,
			Escape: '\\',
		}
	}
|	WHERE Expression
	{
		$$ = $2
	}

GlobalScope:
	{
		$$ = false
	}
|	GLOBAL
	{
		$$ = true
	}
|	SESSION
	{
		$$ = false
	}

OptFull:
	{
		$$ = false
	}
|	FULL
	{
		$$ = true
	}

ShowDatabaseNameOpt:
	{
		$$ =
	}
|	FromOrIn DBName
	{
		$$ = $2.(string)
	}

ShowTableAliasOpt:
	FromOrIn TableName
	{
		$$ = $2.(*ast.TableName)
	}

FlushStmt:
	FLUSH NoWriteToBinLogAliasOpt FlushOption
	{
		tmp := $3.(*ast.FlushStmt)
		tmp.NoWriteToBinLog = $2.(bool)
		$$ = tmp
	}

FlushOption:
	PRIVILEGES
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushPrivileges,
		}
	}
|	STATUS
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushStatus,
		}
	}
|	TableOrTables TableNameListOpt WithReadLockOpt
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushTables,
			Tables: $2.([]*ast.TableName),
			ReadLock: $3.(bool),
		}
	}

NoWriteToBinLogAliasOpt:
	{
		$$ = false
	}
|	NO_WRITE_TO_BINLOG
	{
		$$ = true
	}
|	LOCAL
	{
		$$ = true
	}

TableNameListOpt:
	%prec empty
	{
		$$ = []*ast.TableName{}
	}
|	TableNameList
	{
		$$ = $1
	}

WithReadLockOpt:
	{
		$$ = false
	}
|	WITH READ LOCK
	{
		$$ = true
	}

Statement:
	EmptyStmt
|	AdminStmt
|	AlterTableStmt
|	AlterUserStmt
|	AnalyzeTableStmt
|	BeginTransactionStmt
|	BinlogStmt
|	CommitStmt
|	DeallocateStmt
|	DeleteFromStmt
|	ExecuteStmt
|	ExplainStmt
|	CreateDatabaseStmt
|	CreateIndexStmt
|	CreateTableStmt
|	CreateViewStmt
|	CreateUserStmt
|	CreateBindingStmt
|	DoStmt
|	DropDatabaseStmt
|	DropIndexStmt
|	DropTableStmt
|	DropViewStmt
|	DropUserStmt
|	DropStatsStmt
|	DropBindingStmt
|	FlushStmt
|	GrantStmt
|	InsertIntoStmt
|	KillStmt
|	LoadDataStmt
|	LoadStatsStmt
|	PreparedStmt
|	RollbackStmt
|	RenameTableStmt
|	ReplaceIntoStmt
|	RevokeStmt
|	SelectStmt
|	UnionStmt
|	SetStmt
|	ShowStmt
|	SubSelect
	{
		// `(select 1)`; is a valid select statement
		// TODO: This is used to fix issue #320. There may be a better solution.
		$$ = $1.(*ast.SubqueryExpr).Query.(ast.StmtNode)
	}
|	TraceStmt
|	TruncateTableStmt
|	UpdateStmt
|	UseStmt
|	UnlockTablesStmt
|	LockTablesStmt

TraceableStmt:
	SelectStmt
|	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	UnionStmt

ExplainableStmt:
	SelectStmt
|	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	UnionStmt

StatementList:
	Statement
	{
		if $1 != nil {
			s := $1
			if lexer, ok := yylex.(stmtTexter); ok {
				s.SetText(lexer.stmtText())
			}
			parser.result = append(parser.result, s)
		}
	}
|	StatementList ';' Statement
	{
		if $3 != nil {
			s := $3
			if lexer, ok := yylex.(stmtTexter); ok {
				s.SetText(lexer.stmtText())
			}
			parser.result = append(parser.result, s)
		}
	}

Constraint:
	ConstraintKeywordOpt ConstraintElem
	{
		cst := $2.(*ast.Constraint)
		if $1 != nil {
			cst.Name = $1.(string)
		}
		$$ = cst
	}

TableElement:
	ColumnDef
	{
		$$ = $1.(*ast.ColumnDef)
	}
|	Constraint
	{
		$$ = $1.(*ast.Constraint)
	}
|	CHECK '(' Expression ')'
	{
		/* Nothing to do now */
		$$ = nil
	}

TableElementList:
	TableElement
	{
		if $1 != nil {
			$$ = []interface{}{$1.(interface{})}
		} else {
			$$ = []interface{}{}
		}
	}
|	TableElementList ',' TableElement
	{
		if $3 != nil {
			$$ = append($1.([]interface{}), $3)
		} else {
			$$ = $1
		}
	}

TableElementListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		var columnDefs []*ast.ColumnDef
		var constraints []*ast.Constraint
		$$ = &ast.CreateTableStmt{
			Cols:           columnDefs,
			Constraints:    constraints,
		}
	}
|
	'(' TableElementList ')'
	{
		tes := $2.([]interface {})
		var columnDefs []*ast.ColumnDef
		var constraints []*ast.Constraint
		for _, te := range tes {
			switch te := te.(type) {
			case *ast.ColumnDef:
				columnDefs = append(columnDefs, te)
			case *ast.Constraint:
				constraints = append(constraints, te)
			}
		}
		$$ = &ast.CreateTableStmt{
			Cols:           columnDefs,
			Constraints:    constraints,
		}
	}

TableOption:
	ENGINE StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionEngine, StrValue: $2.(string)}
	}
|	ENGINE eq StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionEngine, StrValue: $3.(string)}
	}
|	DefaultKwdOpt CharsetKw EqOpt CharsetName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCharset, StrValue: $4.(string)}
	}
|	DefaultKwdOpt COLLATE EqOpt StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCollate, StrValue: $4.(string)}
	}
|	AUTO_INCREMENT EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAutoIncrement, UintValue: $3.(uint64)}
	}
|	COMMENT EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionComment, StrValue: $3}
	}
|	AVG_ROW_LENGTH EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAvgRowLength, UintValue: $3.(uint64)}
	}
|	CONNECTION EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionConnection, StrValue: $3}
	}
|	CHECKSUM EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCheckSum, UintValue: $3.(uint64)}
	}
|	PASSWORD EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionPassword, StrValue: $3}
	}
|	COMPRESSION EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCompression, StrValue: $3}
	}
|	KEY_BLOCK_SIZE EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionKeyBlockSize, UintValue: $3.(uint64)}
	}
|	MAX_ROWS EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionMaxRows, UintValue: $3.(uint64)}
	}
|	MIN_ROWS EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionMinRows, UintValue: $3.(uint64)}
	}
|	DELAY_KEY_WRITE EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionDelayKeyWrite, UintValue: $3.(uint64)}
	}
|	RowFormat
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionRowFormat, UintValue: $1.(uint64)}
	}
|	STATS_PERSISTENT EqOpt StatsPersistentVal
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsPersistent}
	}
|	SHARD_ROW_ID_BITS EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionShardRowID, UintValue: $3.(uint64)}
	}
|	PACK_KEYS EqOpt StatsPersistentVal
	{
		// Parse it but will ignore it.
		$$ = &ast.TableOption{Tp: ast.TableOptionPackKeys}
	}

StatsPersistentVal:
	DEFAULT
	{}
|	LengthNum
	{}

AlterTableOptionListOpt:
	{
		$$ = []*ast.TableOption{}
	}
|	TableOptionList %prec higherThanComma

CreateTableOptionListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		$$ = []*ast.TableOption{}
	}
|	TableOptionList %prec lowerThanComma

TableOptionList:
	TableOption
	{
		$$ = []*ast.TableOption{$1.(*ast.TableOption)}
	}
|	TableOptionList TableOption
	{
		$$ = append($1.([]*ast.TableOption), $2.(*ast.TableOption))
	}
|	TableOptionList ','  TableOption
	{
		$$ = append($1.([]*ast.TableOption), $3.(*ast.TableOption))
	}

OptTable:
	{}
|	TABLE

TruncateTableStmt:
	TRUNCATE OptTable TableName
	{
		$$ = &ast.TruncateTableStmt{Table: $3.(*ast.TableName)}
	}

RowFormat:
	 ROW_FORMAT EqOpt DEFAULT
	{
		$$ = ast.RowFormatDefault
	}
|	ROW_FORMAT EqOpt DYNAMIC
	{
		$$ = ast.RowFormatDynamic
	}
|	ROW_FORMAT EqOpt FIXED
	{
		$$ = ast.RowFormatFixed
	}
|	ROW_FORMAT EqOpt COMPRESSED
	{
		$$ = ast.RowFormatCompressed
	}
|	ROW_FORMAT EqOpt REDUNDANT
	{
		$$ = ast.RowFormatRedundant
	}
|	ROW_FORMAT EqOpt COMPACT
	{
		$$ = ast.RowFormatCompact
	}

/*************************************Type Begin***************************************/
Type:
	NumericType
	{
		$$ = $1
	}
|	StringType
	{
		$$ = $1
	}
|	DateAndTimeType
	{
		$$ = $1
	}

NumericType:
	IntegerType OptFieldLen FieldOpts
	{
		// TODO: check flen 0
		x := types.NewFieldType($1.(byte))
		x.Flen = $2.(int)
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				x.Flag |= mysql.UnsignedFlag
			}
			if o.IsZerofill {
				x.Flag |= mysql.ZerofillFlag
			}
		}
		$$ = x
	}
|	BooleanType FieldOpts
	{
		// TODO: check flen 0
		x := types.NewFieldType($1.(byte))
		x.Flen = 1
		for _, o := range $2.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				x.Flag |= mysql.UnsignedFlag
			}
			if o.IsZerofill {
				x.Flag |= mysql.ZerofillFlag
			}
		}
		$$ = x
	}
|	FixedPointType FloatOpt FieldOpts
	{
		fopt := $2.(*ast.FloatOpt)
		x := types.NewFieldType($1.(byte))
		x.Flen = fopt.Flen
		x.Decimal = fopt.Decimal
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				x.Flag |= mysql.UnsignedFlag
			}
			if o.IsZerofill {
				x.Flag |= mysql.ZerofillFlag
			}
		}
		$$ = x
	}
|	FloatingPointType FloatOpt FieldOpts
	{
		fopt := $2.(*ast.FloatOpt)
		x := types.NewFieldType($1.(byte))
		x.Flen = fopt.Flen
		if x.Tp == mysql.TypeFloat {
			if x.Flen > 24 {
				x.Tp = mysql.TypeDouble
			}
		}
		x.Decimal = fopt.Decimal
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				x.Flag |= mysql.UnsignedFlag
			}
			if o.IsZerofill {
				x.Flag |= mysql.ZerofillFlag
			}
		}
		$$ = x
	}
|	BitValueType OptFieldLen
	{
		x := types.NewFieldType($1.(byte))
		x.Flen = $2.(int)
		if x.Flen == types.UnspecifiedLength || x.Flen == 0 {
			x.Flen = 1
		} else if x.Flen > 64 {
			yylex.Errorf(invalid field length %d for bit type, must in [1, 64], x.Flen)
		}
		$$ = x
	}

IntegerType:
	TINYINT
	{
		$$ = mysql.TypeTiny
	}
|	SMALLINT
	{
		$$ = mysql.TypeShort
	}
|	MEDIUMINT
	{
		$$ = mysql.TypeInt24
	}
|	INT
	{
		$$ = mysql.TypeLong
	}
|	INT1
	{
		$$ = mysql.TypeTiny
	}
| 	INT2
	{
		$$ = mysql.TypeShort
	}
| 	INT3
	{
		$$ = mysql.TypeInt24
	}
|	INT4
	{
		$$ = mysql.TypeLong
	}
|	INT8
	{
		$$ = mysql.TypeLonglong
	}
|	INTEGER
	{
		$$ = mysql.TypeLong
	}
|	BIGINT
	{
		$$ = mysql.TypeLonglong
	}


BooleanType:
	BOOL
	{
		$$ = mysql.TypeTiny
	}
|	BOOLEAN
	{
		$$ = mysql.TypeTiny
	}

OptInteger:
	{}
|	INTEGER
|	INT

FixedPointType:
	DECIMAL
	{
		$$ = mysql.TypeNewDecimal
	}
|	NUMERIC
	{
		$$ = mysql.TypeNewDecimal
	}

FloatingPointType:
	FLOAT
	{
		$$ = mysql.TypeFloat
	}
|	REAL
	{
	    if parser.lexer.GetSQLMode().HasRealAsFloatMode() {
		    $$ = mysql.TypeFloat
	    } else {
		    $$ = mysql.TypeDouble
	    }
	}
|	DOUBLE
	{
		$$ = mysql.TypeDouble
	}
|	DOUBLE PRECISION
	{
		$$ = mysql.TypeDouble
	}

BitValueType:
	BIT
	{
		$$ = mysql.TypeBit
	}

StringType:
	NationalOpt CHAR FieldLen OptBinary OptCollate
	{
		x := types.NewFieldType(mysql.TypeString)
		x.Flen = $3.(int)
		x.Charset = $4.(*ast.OptBinary).Charset
		x.Collate = $5.(string)
		if $4.(*ast.OptBinary).IsBinary {
			x.Flag |= mysql.BinaryFlag
		}
		$$ = x
	}
|	NationalOpt CHAR OptBinary OptCollate
	{
		x := types.NewFieldType(mysql.TypeString)
		x.Charset = $3.(*ast.OptBinary).Charset
		x.Collate = $4.(string)
		if $3.(*ast.OptBinary).IsBinary {
			x.Flag |= mysql.BinaryFlag
		}
		$$ = x
	}
|	NATIONAL CHARACTER FieldLen OptBinary OptCollate
	{
		x := types.NewFieldType(mysql.TypeString)
		x.Flen = $3.(int)
		x.Charset = $4.(*ast.OptBinary).Charset
		x.Collate = $5.(string)
		if $4.(*ast.OptBinary).IsBinary {
			x.Flag |= mysql.BinaryFlag
		}
		$$ = x
	}
|	Varchar FieldLen OptBinary OptCollate
	{
		x := types.NewFieldType(mysql.TypeVarchar)
		x.Flen = $2.(int)
		x.Charset = $3.(*ast.OptBinary).Charset
		x.Collate = $4.(string)
		if $3.(*ast.OptBinary).IsBinary {
			x.Flag |= mysql.BinaryFlag
		}
		$$ = x
	}
|	BINARY OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeString)
		x.Flen = $2.(int)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CharsetBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	VARBINARY FieldLen
	{
		x := types.NewFieldType(mysql.TypeVarchar)
		x.Flen = $2.(int)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CharsetBin
		x.Flag |= mysql.BinaryFlag
		$$ = x
	}
|	BlobType
	{
		x := $1.(*types.FieldType)
		x.Charset = charset.CharsetBin
		x.Collate = charset.CharsetBin
		x.Flag |= mysql.BinaryFlag
		$$ = $1.(*types.FieldType)
	}
|	TextType OptBinary OptCollate
	{
		x := $1.(*types.FieldType)
		x.Charset = $2.(*ast.OptBinary).Charset
		x.Collate = $3.(string)
		if $2.(*ast.OptBinary).IsBinary {
			x.Flag |= mysql.BinaryFlag
		}
		$$ = x
	}
|	ENUM '(' StringList ')' OptCharset OptCollate
	{
		x := types.NewFieldType(mysql.TypeEnum)
		x.Elems = $3.([]string)
		x.Charset = $5.(string)
		x.Collate = $6.(string)
		$$ = x
	}
|	SET '(' StringList ')' OptCharset OptCollate
	{
		x := types.NewFieldType(mysql.TypeSet)
		x.Elems = $3.([]string)
		x.Charset = $5.(string)
		x.Collate = $6.(string)
		$$ = x
	}
|	JSON
	{
		x := types.NewFieldType(mysql.TypeJSON)
		x.Decimal = 0
		x.Charset = charset.CharsetBin
		x.Collate = charset.CollationBin
		$$ = x
	}

NationalOpt:
	{}
|	NATIONAL

Varchar:
NATIONAL VARCHAR
| VARCHAR
| NVARCHAR


BlobType:
	TINYBLOB
	{
		x := types.NewFieldType(mysql.TypeTinyBlob)
		$$ = x
	}
|	BLOB OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeBlob)
		x.Flen = $2.(int)
		$$ = x
	}
|	MEDIUMBLOB
	{
		x := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = x
	}
|	LONGBLOB
	{
		x := types.NewFieldType(mysql.TypeLongBlob)
		$$ = x
	}

TextType:
	TINYTEXT
	{
		x := types.NewFieldType(mysql.TypeTinyBlob)
		$$ = x

	}
|	TEXT OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeBlob)
		x.Flen = $2.(int)
		$$ = x
	}
|	MEDIUMTEXT
	{
		x := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = x
	}
|	LONGTEXT
	{
		x := types.NewFieldType(mysql.TypeLongBlob)
		$$ = x
	}
|	LONG VARCHAR
	{
		x := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = x
	}


DateAndTimeType:
	DATE
	{
		x := types.NewFieldType(mysql.TypeDate)
		$$ = x
	}
|	DATETIME OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeDatetime)
		x.Flen = mysql.MaxDatetimeWidthNoFsp
		x.Decimal = $2.(int)
		if x.Decimal > 0 {
			x.Flen = x.Flen + 1 + x.Decimal
		}
		$$ = x
	}
|	TIMESTAMP OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeTimestamp)
		x.Flen = mysql.MaxDatetimeWidthNoFsp
		x.Decimal = $2.(int)
		if x.Decimal > 0 {
			x.Flen = x.Flen + 1 + x.Decimal
		}
		$$ = x
	}
|	TIME OptFieldLen
	{
		x := types.NewFieldType(mysql.TypeDuration)
		x.Flen = mysql.MaxDurationWidthNoFsp
		x.Decimal = $2.(int)
		if x.Decimal > 0 {
			x.Flen = x.Flen + 1 + x.Decimal
		}
		$$ = x
	}
|	YEAR OptFieldLen FieldOpts
	{
		x := types.NewFieldType(mysql.TypeYear)
		x.Flen = $2.(int)
		if x.Flen != types.UnspecifiedLength && x.Flen != 4 {
			yylex.Errorf(Supports only YEAR or YEAR(4) column.)
			return -1
		}
		$$ = x
	}

FieldLen:
	'(' LengthNum ')'
	{
		$$ = int($2.(uint64))
	}

OptFieldLen:
	{
		$$ = types.UnspecifiedLength
	}
|	FieldLen
	{
		$$ = $1.(int)
	}

FieldOpt:
	UNSIGNED
	{
		$$ = &ast.TypeOpt{IsUnsigned: true}
	}
|	SIGNED
	{
		$$ = &ast.TypeOpt{IsUnsigned: false}
	}
|	ZEROFILL
	{
		$$ = &ast.TypeOpt{IsZerofill: true, IsUnsigned: true}
	}

FieldOpts:
	{
		$$ = []*ast.TypeOpt{}
	}
|	FieldOpts FieldOpt
	{
		$$ = append($1.([]*ast.TypeOpt), $2.(*ast.TypeOpt))
	}

FloatOpt:
	{
		$$ = &ast.FloatOpt{Flen: types.UnspecifiedLength, Decimal: types.UnspecifiedLength}
	}
|	FieldLen
	{
		$$ = &ast.FloatOpt{Flen: $1.(int), Decimal: types.UnspecifiedLength}
	}
|	Precision
	{
		$$ = $1.(*ast.FloatOpt)
	}

Precision:
	'(' LengthNum ',' LengthNum ')'
	{
		$$ = &ast.FloatOpt{Flen: int($2.(uint64)), Decimal: int($4.(uint64))}
	}

OptBinMod:
	{
		$$ = false
	}
|	BINARY
	{
		$$ = true
	}

OptBinary:
	{
		$$ = &ast.OptBinary{
			IsBinary: false,
			Charset:  ,
		}
	}
|	BINARY OptCharset
	{
		$$ = &ast.OptBinary{
			IsBinary: true,
			Charset:  $2.(string),
		}
	}
|	CharsetKw CharsetName OptBinMod
	{
		$$ = &ast.OptBinary{
			IsBinary: $3.(bool),
			Charset:  $2.(string),
		}
	}

OptCharset:
	{
		$$ =
	}
|	CharsetKw CharsetName
	{
		$$ = $2.(string)
	}

CharsetKw:
	CHARACTER SET
|	CHARSET

OptCollate:
	{
		$$ =
	}
|	COLLATE StringName
	{
		$$ = $2.(string)
	}

StringList:
	stringLit
	{
		$$ = []string{$1}
	}
|	StringList ',' stringLit
	{
		$$ = append($1.([]string), $3)
	}

StringName:
	stringLit
	{
		$$ = $1
	}
|	Identifier
	{
		$$ = $1
	}

/***********************************************************************************
 * Update Statement
 * See https://dev.mysql.com/doc/refman/5.7/en/update.html
 ***********************************************************************************/
UpdateStmt:
	UPDATE TableOptimizerHints PriorityOpt IgnoreOptional TableRef SET AssignmentList WhereClauseOptional OrderByOptional LimitClause
	{
		var refs *ast.Join
		if x, ok := $5.(*ast.Join); ok {
			refs = x
		} else {
			refs = &ast.Join{Left: $5.(ast.ResultSetNode)}
		}
		st := &ast.UpdateStmt{
			Priority:  $3.(mysql.PriorityEnum),
			TableRefs: &ast.TableRefsClause{TableRefs: refs},
			List:	   $7.([]*ast.Assignment),
			IgnoreErr: $4.(bool),
		}
		if $2 != nil {
			st.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $8 != nil {
			st.Where = $8.(ast.ExprNode)
		}
		if $9 != nil {
			st.Order = $9.(*ast.OrderByClause)
		}
		if $10 != nil {
			st.Limit = $10.(*ast.Limit)
		}
		$$ = st
	}
|	UPDATE TableOptimizerHints PriorityOpt IgnoreOptional TableRefs SET AssignmentList WhereClauseOptional
	{
		st := &ast.UpdateStmt{
			Priority:  $3.(mysql.PriorityEnum),
			TableRefs: &ast.TableRefsClause{TableRefs: $5.(*ast.Join)},
			List:	   $7.([]*ast.Assignment),
			IgnoreErr: $4.(bool),
		}
		if $2 != nil {
			st.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $8 != nil {
			st.Where = $8.(ast.ExprNode)
		}
		$$ = st
	}

UseStmt:
	USE DBName
	{
		$$ = &ast.UseStmt{DBName: $2.(string)}
	}

WhereClause:
	WHERE Expression
	{
		$$ = $2
	}

WhereClauseOptional:
	{
		$$ = nil
	}
|	WhereClause
	{
		$$ = $1
	}

CommaOpt:
	{}
|	','
	{}

/************************************************************************************
 *  Account Management Statements
 *  https://dev.mysql.com/doc/refman/5.7/en/account-management-sql.html
 ************************************************************************************/
CreateUserStmt:
	CREATE USER IfNotExists UserSpecList
	{
 		// See https://dev.mysql.com/doc/refman/5.7/en/create-user.html
		$$ = &ast.CreateUserStmt{
			IfNotExists: $3.(bool),
			Specs: $4.([]*ast.UserSpec),
		}
	}

/* See http://dev.mysql.com/doc/refman/5.7/en/alter-user.html */
AlterUserStmt:
	ALTER USER IfExists UserSpecList
	{
		$$ = &ast.AlterUserStmt{
			IfExists: $3.(bool),
			Specs: $4.([]*ast.UserSpec),
		}
	}
| 	ALTER USER IfExists USER '(' ')' IDENTIFIED BY AuthString
	{
		auth := &ast.AuthOption {
			AuthString: $9.(string),
			ByAuthString: true,
		}
		$$ = &ast.AlterUserStmt{
			IfExists: $3.(bool),
			CurrentAuth: auth,
		}
	}

UserSpec:
	Username AuthOption
	{
		userSpec := &ast.UserSpec{
			User: $1.(*auth.UserIdentity),
		}
		if $2 != nil {
			userSpec.AuthOpt = $2.(*ast.AuthOption)
		}
		$$ = userSpec
	}

UserSpecList:
	UserSpec
	{
		$$ = []*ast.UserSpec{$1.(*ast.UserSpec)}
	}
|	UserSpecList ',' UserSpec
	{
		$$ = append($1.([]*ast.UserSpec), $3.(*ast.UserSpec))
	}

AuthOption:
	{
		$$ = nil
	}
|	IDENTIFIED BY AuthString
	{
		$$ = &ast.AuthOption {
			AuthString: $3.(string),
			ByAuthString: true,
		}
	}
|	IDENTIFIED WITH StringName
	{
		$$ = nil
	}
|	IDENTIFIED WITH StringName BY AuthString
	{
		$$ = &ast.AuthOption {
			AuthString: $5.(string),
			ByAuthString: true,
		}
	}
|	IDENTIFIED WITH StringName AS HashString
	{
		$$ = &ast.AuthOption{
			HashString: $5.(string),
		}
	}
|	IDENTIFIED BY PASSWORD HashString
	{
		$$ = &ast.AuthOption{
			HashString: $4.(string),
		}
	}

HashString:
	stringLit
	{
		$$ = $1
	}

/*******************************************************************
 *
 *  Create Binding Statement
 *
 *  Example:
 *      CREATE GLOBAL BINDING FOR select Col1,Col2 from table USING select Col1,Col2 from table use index(Col1)
 *******************************************************************/
CreateBindingStmt:
	CREATE GlobalScope BINDING FOR SelectStmt USING SelectStmt
    	{
		startOffset := parser.startOffset(&yyS[yypt-2])
        	endOffset := parser.startOffset(&yyS[yypt-1])
        	selStmt := $5.(*ast.SelectStmt)
        	selStmt.SetText(strings.TrimSpace(parser.src[startOffset:endOffset]))

		startOffset = parser.startOffset(&yyS[yypt])
		hintedSelStmt := $7.(*ast.SelectStmt)
		hintedSelStmt.SetText(strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.CreateBindingStmt {
			OriginSel:  selStmt,
			HintedSel:  hintedSelStmt,
			GlobalScope: $2.(bool),
		}

		$$ = x
	}
/*******************************************************************
 *
 *  Drop Binding Statement
 *
 *  Example:
 *      DROP GLOBAL BINDING FOR select Col1,Col2 from table
 *******************************************************************/
DropBindingStmt:
	DROP GlobalScope BINDING FOR SelectStmt
	{
		startOffset := parser.startOffset(&yyS[yypt])
		selStmt := $5.(*ast.SelectStmt)
		selStmt.SetText(strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.DropBindingStmt {
			OriginSel:  selStmt,
			GlobalScope: $2.(bool),
		}

		$$ = x
	}

/*************************************************************************************
 * Grant statement
 * See https://dev.mysql.com/doc/refman/5.7/en/grant.html
 *************************************************************************************/
GrantStmt:
	 GRANT PrivElemList ON ObjectType PrivLevel TO UserSpecList WithGrantOptionOpt
	 {
		$$ = &ast.GrantStmt{
			Privs: $2.([]*ast.PrivElem),
			ObjectType: $4.(ast.ObjectTypeType),
			Level: $5.(*ast.GrantLevel),
			Users: $7.([]*ast.UserSpec),
			WithGrant: $8.(bool),
		}
	 }

WithGrantOptionOpt:
	{
		$$ = false
	}
|	WITH GRANT OPTION
	{
		$$ = true
	}
|	WITH MAX_QUERIES_PER_HOUR NUM
	{
		$$ = false
	}
|	WITH MAX_UPDATES_PER_HOUR NUM
	{
		$$ = false
	}
|	WITH MAX_CONNECTIONS_PER_HOUR NUM
	{
		$$ = false
	}
|	WITH MAX_USER_CONNECTIONS NUM
	{
		$$ = false
	}

PrivElem:
	PrivType
	{
		$$ = &ast.PrivElem{
			Priv: $1.(mysql.PrivilegeType),
		}
	}
|	PrivType '(' ColumnNameList ')'
	{
		$$ = &ast.PrivElem{
			Priv: $1.(mysql.PrivilegeType),
			Cols: $3.([]*ast.ColumnName),
		}
	}

PrivElemList:
	PrivElem
	{
		$$ = []*ast.PrivElem{$1.(*ast.PrivElem)}
	}
|	PrivElemList ',' PrivElem
	{
		$$ = append($1.([]*ast.PrivElem), $3.(*ast.PrivElem))
	}

PrivType:
	ALL
	{
		$$ = mysql.AllPriv
	}
|	ALL PRIVILEGES
	{
		$$ = mysql.AllPriv
	}
|	ALTER
	{
		$$ = mysql.AlterPriv
	}
|	CREATE
	{
		$$ = mysql.CreatePriv
	}
|	CREATE USER
	{
		$$ = mysql.CreateUserPriv
	}
|	TRIGGER
	{
		$$ = mysql.TriggerPriv
	}
|	DELETE
	{
		$$ = mysql.DeletePriv
	}
|	DROP
	{
		$$ = mysql.DropPriv
	}
|	PROCESS
	{
		$$ = mysql.ProcessPriv
	}
|	EXECUTE
	{
		$$ = mysql.ExecutePriv
	}
|	INDEX
	{
		$$ = mysql.IndexPriv
	}
|	INSERT
	{
		$$ = mysql.InsertPriv
	}
|	SELECT
	{
		$$ = mysql.SelectPriv
	}
|	SUPER
	{
		$$ = mysql.SuperPriv
	}
|	SHOW DATABASES
	{
		$$ = mysql.ShowDBPriv
	}
|	UPDATE
	{
		$$ = mysql.UpdatePriv
	}
|	GRANT OPTION
	{
		$$ = mysql.GrantPriv
	}
|	REFERENCES
	{
		$$ = mysql.ReferencesPriv
	}
|	REPLICATION SLAVE
	{
		$$ = mysql.PrivilegeType(0)
	}
|	REPLICATION CLIENT
	{
		$$ = mysql.PrivilegeType(0)
	}
|	USAGE
	{
		$$ = mysql.PrivilegeType(0)
	}
|	RELOAD
	{
		$$ = mysql.PrivilegeType(0)
	}
|	CREATE TEMPORARY TABLES
	{
		$$ = mysql.PrivilegeType(0)
	}
|	LOCK TABLES
	{
		$$ = mysql.PrivilegeType(0)
	}
|	CREATE VIEW
	{
		$$ = mysql.PrivilegeType(0)
	}
|	SHOW VIEW
	{
		$$ = mysql.PrivilegeType(0)
	}
|	CREATE ROUTINE
	{
		$$ = mysql.PrivilegeType(0)
	}
|	ALTER ROUTINE
	{
		$$ = mysql.PrivilegeType(0)
	}
|	EVENT
	{
		$$ = mysql.PrivilegeType(0)
	}

ObjectType:
	{
		$$ = ast.ObjectTypeNone
	}
|	TABLE
	{
		$$ = ast.ObjectTypeTable
	}

PrivLevel:
	'*'
	{
		$$ = &ast.GrantLevel {
			Level: ast.GrantLevelDB,
		}
	}
|	'*' '.' '*'
	{
		$$ = &ast.GrantLevel {
			Level: ast.GrantLevelGlobal,
		}
	}
| 	Identifier '.' '*'
	{
		$$ = &ast.GrantLevel {
			Level: ast.GrantLevelDB,
			DBName: $1,
		}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.GrantLevel {
			Level: ast.GrantLevelTable,
			DBName: $1,
			TableName: $3,
		}
	}
|	Identifier
	{
		$$ = &ast.GrantLevel {
			Level: ast.GrantLevelTable,
			TableName: $1,
		}
	}

/**************************************RevokeStmt*******************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/revoke.html
 *******************************************************************************************/
RevokeStmt:
	 REVOKE PrivElemList ON ObjectType PrivLevel FROM UserSpecList
	 {
		$$ = &ast.RevokeStmt{
			Privs: $2.([]*ast.PrivElem),
			ObjectType: $4.(ast.ObjectTypeType),
			Level: $5.(*ast.GrantLevel),
			Users: $7.([]*ast.UserSpec),
		}
	 }

/**************************************LoadDataStmt*****************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/load-data.html
 *******************************************************************************************/
LoadDataStmt:
	LOAD DATA LocalOpt INFILE stringLit INTO TABLE TableName CharsetOpt Fields Lines IgnoreLines ColumnNameListOptWithBrackets
	{
		x := &ast.LoadDataStmt{
			Path:       $5,
			Table:      $8.(*ast.TableName),
			Columns:    $13.([]*ast.ColumnName),
			IgnoreLines:$12.(uint64),
		}
		if $3 != nil {
			x.IsLocal = true
		}
		if $10 != nil {
			x.FieldsInfo = $10.(*ast.FieldsClause)
		}
		if $11 != nil {
			x.LinesInfo = $11.(*ast.LinesClause)
		}
		$$ = x
	}

IgnoreLines:
    {
        $$ = uint64(0)
    }
|   IGNORE NUM LINES
    {
        $$ = getUint64FromNUM($2)
    }

CharsetOpt:
	{}
|	CHARACTER SET CharsetName

LocalOpt:
	{
		$$ = nil
	}
|	LOCAL
	{
		$$ = $1
	}

Fields:
     	{
		escape := \\
		$$ = &ast.FieldsClause{
			Terminated: \t,
			Escaped:    escape[0],
		}
	}
|	FieldsOrColumns FieldsTerminated Enclosed Escaped
	{
		escape := $4.(string)
		if escape != \\ && len(escape) > 1 {
			yylex.Errorf(Incorrect arguments %s to ESCAPE, escape)
			return 1
		}
		var enclosed byte
		str := $3.(string)
		if len(str) > 1 {
			yylex.Errorf(Incorrect arguments %s to ENCLOSED, escape)
			return 1
		}else if len(str) != 0 {
			enclosed = str[0]
		}
		var escaped byte
		if len(escape) > 0 {
			escaped = escape[0]
		}
		$$ = &ast.FieldsClause{
			Terminated: $2.(string),
			Enclosed:   enclosed,
			Escaped:    escaped,
		}
	}

FieldsOrColumns:
FIELDS
| COLUMNS

FieldsTerminated:
	{
		$$ = \t
	}
|	TERMINATED BY stringLit
	{
		$$ = $3
	}

Enclosed:
	{
		$$ =
	}
|	ENCLOSED BY stringLit
	{
		$$ = $3
	}

Escaped:
	{
		$$ = \\
	}
|	ESCAPED BY stringLit
	{
		$$ = $3
	}

Lines:
	{
		$$ = &ast.LinesClause{Terminated: \n}
	}
|	LINES Starting LinesTerminated
	{
		$$ = &ast.LinesClause{Starting: $2.(string), Terminated: $3.(string)}
	}

Starting:
	{
		$$ =
	}
|	STARTING BY stringLit
	{
		$$ = $3
	}

LinesTerminated:
	{
		$$ = \n
	}
|	TERMINATED BY stringLit
	{
		$$ = $3
	}


/*********************************************************************
 * Lock/Unlock Tables
 * See http://dev.mysql.com/doc/refman/5.7/en/lock-tables.html
 * All the statement leaves empty. This is used to prevent mysqldump error.
 *********************************************************************/

UnlockTablesStmt:
	UNLOCK TablesTerminalSym {}

LockTablesStmt:
	LOCK TablesTerminalSym TableLockList
	{}

TablesTerminalSym:
	TABLES
|	TABLE

TableLock:
	TableName LockType

LockType:
	READ
|	READ LOCAL
|	WRITE

TableLockList:
	TableLock
|	TableLockList ',' TableLock


/********************************************************************
 * Kill Statement
 * See https://dev.mysql.com/doc/refman/5.7/en/kill.html
 *******************************************************************/

KillStmt:
	KillOrKillTiDB NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID: getUint64FromNUM($2),
			TiDBExtension: $1.(bool),
		}
	}
|	KillOrKillTiDB CONNECTION NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID: getUint64FromNUM($3),
			TiDBExtension: $1.(bool),
		}
	}
|	KillOrKillTiDB QUERY NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID: getUint64FromNUM($3),
			Query: true,
			TiDBExtension: $1.(bool),
		}
	}

KillOrKillTiDB:
	KILL
	{
		$$ = false
	}
/* KILL TIDB is a special grammar extension in TiDB, it can be used only when
   the client connect to TiDB directly, not proxied under LVS. */
|	KILL TIDB
	{
		$$ = true
	}

/*******************************************************************************************/

LoadStatsStmt:
	LOAD STATS stringLit
	{
		$$ = &ast.LoadStatsStmt{
			Path:       $3,
		}
	}

%%
