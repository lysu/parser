// Copyright 2018 PingCAP, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// See the License for the specific language governing permissions and
// limitations under the License.

package parser_test

import (
	"fmt"
	"github.com/pingcap/parser"
	// 0. import parser_driver implemented by TiDB(user also can implement own driver by self).
	_ "github.com/pingcap/tidb/types/parser_driver"
)

// This example show how to parse a text sql into ast.
func Example_parseSQL() {

	// 1. Create a parser, this is a NOT thread-safe but heavy object,
	// it is better to reuse it in thread-safe way as possible  as we can.
	p := parser.New()

	// 2. Parse a text SQL into AST([]ast.StmtNode)
	stmtNodes, err := p.Parse("select * from tbl where id = 1", "", "")

	// 3. Use AST to do cool things~
	fmt.Println(stmtNodes[0], err)
}
