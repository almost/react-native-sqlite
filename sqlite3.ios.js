var NativeModules = require('react-native').NativeModules;
var RCTDeviceEventEmitter = require('RCTDeviceEventEmitter');

var nextId = 0;

function SQLite3Error(message) {
 this.message = message;
}

SQLite3Error.prototype = new Error();

function Database(databaseId) {
  this._databaseId = databaseId;
}

Database.prototype = {
  executeSQL(sql: string, params: Array, rowCallback: (row: Object) => void, completeCallback: (error: ?SQLite3Error) => void) {
    var eventName =  "aibSqliteRow:" + (nextId++);
    var rowHandler = RCTDeviceEventEmitter.addListener(
      eventName,
      rowCallback
    );

    NativeModules.AIBSQLite.execOnDatabase(this._databaseId, sql, params, eventName, function (error) {
      rowHandler.remove();
      if (error) {
        completeCallback(new SQLite3Error(error));
      } else {
        completeCallback(null);
      }
    });
  },

  close (callback: ?(error: ?SQLite3Error) => void) {
    NativeModules.AIBSQLite.closeDatabase(this._databaseId, (error) => {
      if (!callback) return;
      if (error) {
        callback(new SQLite3Error(error));
      } else {
        callback(null);
      }
    });
  }
};

module.exports = {
  SQLite3Error: SQLite3Error,
  open (databaseName: string, callback: (error: ?SQLite3Error, database: ?Database) => void ) {
    NativeModules.AIBSQLite.openFromFilename(databaseName, (error, databaseId) => {
      if (error) {
        return callback(new SQLite3Error(error), null);
      }
      callback(null, new Database(databaseId));
    });
  }
};
