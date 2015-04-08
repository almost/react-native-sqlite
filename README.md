# react-native-sqlite

A binding for sqlite3 for React Native. Allows a database to be opened and for SQL queries to be run on it.

Really early version right now, the API might change and I'm still figuring out the best way to do things with React Native.

Written by Thomas Parslow
([almostobsolete.net](http://almostobsolete.net) and
[tomparslow.co.uk](http://tomparslow.co.uk)) as part of Active Inbox
([activeinboxhq.com](http://activeinboxhq.com/)).

## Installation

Install using npm with `npm install --save react-native-sqlite`

You then need to add the Objective C part to your XCode project. Drag
`AIBSQLite.xcodeproj` from the `node_modules/react-native-sqlite` folder into your XCode projec. Click on the your project in XCode, goto `Build Phases` then `Link Binary With Libraries` and add `libAIBSQLite.a` and `libsqlite3.dylib`.

NOTE: Make sure you don't have the `AIBSQLite` project open seperately in XCode otherwise it won't work.

## Usage

```javascript
var sqlite = require('react-native-sqlite');
sqlite.open("filename.sqlite", function (error, database) {
  if (error) {
    console.log("Failed to open database:", error);
    return;
  }
  var sql = "SELECT a, b FROM table WHERE field=? AND otherfield=?";
  var params = ["somestring", 99];
  database.executeSQL(sql, params, rowCallback, completeCallback);
  function rowCallback(rowData) {
    console.log("Got row data:", rowData);
  }
  function completeCallback(error) {
    if (error) {
      console.log("Failed to execute query:", error);
      return
    }
    console.log("Query complete!");
    database.close(function (error) {
      if (error) {
        console.log("Failed to close database:", error);
        return
      }
    });
  }
});
```

## Database Location

It will first look for the database filename you give in the `Documents` directory inside the app sandbox. If it doesn't find anything there it will look in the app bundle and try and copy it to the `Documents` directory. If it doesn't find the database in either place then it will create a new blank database in the `Documents` directory.

In the future it should probably be made possible to open/create databases in the `tmp` and `Libraries` directories.

## Known Issues

- Doesn't support reading of BLOB fields right now. I'm not entirely sure what would be the best way to pass back binary data. Maybe Base64?
- Database needs to be closed manually. I'm not sure how I could do
  this automatically.


## Feedback Welcome!

Feedback, questions, suggestions and most of all Pull Requests are
very welcome. This is an early version and I want to figure out the
best way to continue it.

I'm also available for freelance work!

I'm [@almostobsolete](http://twitter.com/almostobsolete) on Twitter my
email is [tom@almostobsolete.net](mailto:tom@almostobsolete.net) and
you can find me on the web at
[tomparslow.co.uk](http://tomparslow.co.uk) and
[almostobsolete.net](http://almostobsolete.net)
