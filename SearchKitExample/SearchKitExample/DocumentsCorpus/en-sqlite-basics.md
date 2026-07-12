---
id: en-sqlite-basics
title: SQLite Fundamentals for App Developers
language: en
family: data-persistence
---
SQLite is a complete relational database packed into a C library that writes to a single file. There is no server process and no setup; every iPhone ships with it, and most apps on your device quietly depend on it.

Working with the raw C API means a strict lifecycle: prepare a statement, bind parameters by index, step through result rows, finalize. Always bind values instead of concatenating them into SQL — bound parameters eliminate injection risks and handle quoting, encodings, and blobs correctly.

Performance in SQLite is mostly about transactions and indexes. Individual inserts each pay a commit; wrapping a batch in one transaction turns thousands of writes into one fsync. Write-ahead logging (WAL) mode lets readers proceed while a writer works, which matters for responsive UIs. `EXPLAIN QUERY PLAN` tells you whether a query walks an index or scans the table.

The extension ecosystem is a superpower: FTS5 adds full-text search with BM25 ranking, JSON functions query semi-structured columns, and loadable extensions like sqlite-vec bring vector similarity search for on-device AI features — all in the same transactional file, queryable with joins across regular tables.
