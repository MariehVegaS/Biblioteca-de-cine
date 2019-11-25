
const oracledb = require('oracledb');
const database = require('../services/database.js');
const connectionName = 'musicStore';

const baseQuery =
    `SELECT ARTIST_COD "artistCod",
    ARTIST_NAME "artistName",
    GENRE "genre",
    BIOGRAFY "biografy"
FROM ARTISTS`;

const paginator = '\n' +
    `OFFSET :offset ROWS
FETCH NEXT :fetch ROWS ONLY`;

async function find(context) {
    let query;
    const binds = {};
    const orderParts = (context.order || 'ARTIST_COD:ASC').split(':');
    let orderCol = orderParts[0];
    const orderDir = orderParts[1];

    if (orderCol === 'id') {
        orderCol = 'ARTIST_COD';
    }

    if (context.id) {
        binds.artist_cod = context.id;

        query = baseQuery + `\nWHERE ARTIST_COD = :artist_cod`;// +
        //+ `\nORDER BY ${orderCol} ${orderDir}`+
        // paginator;
    } else {
        binds.offset = context.offset || 0;
        binds.fetch = context.limit || 100;
        query = baseQuery +
            `\nORDER BY ${orderCol} ${orderDir}` +
            paginator;
    }

    console.log(query);

    const result = await database.simpleExecute(connectionName, query, binds, { fetchInfo: { "biografy": { type: oracledb.STRING } } });

    return result.rows;
}

module.exports.find = find;

const selectImageBase64Sql =
    `BEGIN :imgBase64 := base64encode(:cod); END;`;

async function findImage(context) {
console.log('Query image start');
    const binds = {};
    binds.cod = context.id;
    binds.imgBase64 = { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 50000 };

    const result = await database.simpleExecute(selectImageBase64Sql, binds);
    return result.outBinds;
}

module.exports.findImage = findImage;

const createSql =
    `BEGIN Insertar_ImagenBD(:artist_name, :genre, :biografy, :img_name); END;`;

async function create(artist) {
    /*artist.artist_cod = {
        dir: oracledb.BIND_OUT,
        type: oracledb.NUMBER
    }*/

    const result = await database.simpleExecute(connectionName, createSql, artist);


    //artist.artist_cod = result.outBinds.artist_cod[0];

    return artist;
}

module.exports.create = create;

const updateSql =
    `UPDATE ARTISTS SET
        ARTIST_NAME = :artist_name,
        GENRE = :genre,
        BIOGRAFY = :biografy,
        IMAGE = :image
        WHERE ARTIST_COD = :artist_cod`;

async function update(artist) {

    const result = await database.simpleExecute(connectionName, updateSql, artist);

    return artist;
}

module.exports.update = update;

const deleteSql =
    `DELETE ARTISTS WHERE ARTIST_COD = :artist_cod`;

async function del(id) {

    const result = await database.simpleExecute(connectionName, deleteSql, { 'artist_cod': id });

}

module.exports.delete = del;
