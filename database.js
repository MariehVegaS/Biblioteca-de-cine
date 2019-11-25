const oracledb = require('oracledb');
const connections = require('./connections');
const connectionKeys = Object.keys(connections);

oracledb.fetchAsString = [ oracledb.CLOB ];

async function openConnections() {
    for (let x = 0; x < connectionKeys.length; x++) {
        const connInfo = connections[connectionKeys[x]];
        
        const pool =await oracledb.createPool({
            user: connInfo.user,
            password: connInfo.password,
            connectString: connInfo.connectString,
            poolAlias: connectionKeys[x],
            poolMin: connInfo.poolMin,
            poolMax: connInfo.poolMax,
            poolIncrement: connInfo.poolIncrement,
            _enableStats: connInfo._enableStats
         });

    const conn = await pool.getConnection(); //ensures user/pass is valid
    await conn.close();
    }
}

module.exports.openConnections = openConnections;

function simpleExecute(poolAlias, statement, binds = [], opts = {}) {
    return new Promise(async (resolve, reject) => {
      let conn;
      let result;
      let err;
   
      opts.outFormat = oracledb.OBJECT;
      opts.autoCommit = true;
   
      try {
        conn = await oracledb.getPool(poolAlias).getConnection();
   
        result = await conn.execute(statement, binds, opts);
   
        resolve(result);
      } catch (err) {
        reject(err);
      } finally {
        if (conn) {
          try {
            await conn.close();
          } catch (err) {
            console.log(err);
          }
        }
      }
    });
  }
   
  module.exports.simpleExecute = simpleExecute;