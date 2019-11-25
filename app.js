const express = require('express');
const database = require('./database');
const connectionName = 'BibliotecaCine';
const bodyParser = require('body-parser');


const app = express();
const router = express.Router();
const port = process.env.PORT || 3000;
process.env.UV_THREADPOOL_SIZE = 3;

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

router.route('/Peliculas')
    .get(async (req, res) => {
        const cantidad = `SELECT COUNT(*) as Peliculas_Disponibles
        FROM PELICULAS`;
        const peliculas = `SELECT ID_PELICULA, TITULO
        FROM PELICULAS`;
        try {
            const result1 = await database.simpleExecute(connectionName, cantidad, []);
            const result2 = await database.simpleExecute(connectionName, peliculas, []);
            const result = {
                Cantidad: result1.rows,
                Peliculas: result2.rows
            }
            console.log(result.Cantidad[0].PELICULAS_DISPONIBLES);
            res.json(result);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {
        try {

            //Validaciones para generar el ID (tochemente)
            const cantidad = await database.simpleExecute(connectionName, `SELECT COUNT(*) as Peliculas_Disponibles
        FROM PELICULAS`, []);
            let conteo = (cantidad.rows[0].PELICULAS_DISPONIBLES) + 1;
            let newID;
            if (conteo == 10 || conteo == 100 || conteo == 1000 || conteo == 10000) {
                conteo = conteo + 1;
            }
            if (conteo < 10) {
                newID = `${conteo}0000`;
            }
            if (conteo > 10 && conteo < 100) {
                newID = `${conteo}000`;
            }
            if (conteo > 100 && conteo < 1000) {
                newID = `${conteo}00`;
            }
            if (conteo > 1000 && conteo < 10000) {
                newID = `${conteo}0`;
            }
            if (conteo > 10000 && conteo < 99999) {
                newID = `${conteo}`;
            }

            //Validacion para el ID del director
            let director = req.body.ID_DIRECTOR;
            let exist = false;
            if (director && director.length == 5) {
                const directores = await database.simpleExecute(connectionName, `SELECT ID_DIRECTOR
            FROM DIRECTOR`, []);
                (directores.rows).forEach(element => {
                    if (element.ID_DIRECTOR == `${director}`) {
                        exist = true;
                    }
                });
                if (exist == false) {
                    //Crear un nuevo director
                    const nuevo = await database.simpleExecute(connectionName, `INSERT INTO DIRECTOR 
                (ID_DIRECTOR, NOMBRE, EDAD) VALUES ('${director}', '${req.body.NOMBRE_DIRECTOR || "No definido"}', ${req.body.EDAD_DIRECTOR || 00})`, []);
                    console.log(nuevo);
                }
            } else {
                director = "00001";
            }

            //Validacion para subir un docsito
            //Vamos a crear su procedimiento así no quiera...

            let guiones = req.body.GUIONES;
            const procedure =
            `create or replace procedure Insertar_DocsBD(vCodigo CHAR, vArchivo varchar2) IS
            doc ordsys.orddoc;
            ctx raw(64) := null;
        BEGIN
            SELECT guiones INTO doc FROM PELICULAS
            WHERE id_pelicula = vCodigo FOR UPDATE;
            DBMS_OUTPUT.PUT_LINE('setting and getting source');
            DBMS_OUTPUT.PUT_LINE('--------------------------');
            -- set source to a file
            -- import data
            doc.importFrom(ctx, 'file', 'MULTIMEDIA', vArchivo, FALSE);
            -- check size
            DBMS_OUTPUT.PUT_LINE('Length:' ||TO_CHAR(DBMS_LOB.getLength(doc.getContent())));
            UPDATE PELICULAS SET guiones=doc WHERE id_pelicula=vCodigo;
            COMMIT;
            EXCEPTION
            WHEN ORDSYS.ORDSourceExceptions.METHOD_NOT_SUPPORTED THEN
                DBMS_OUTPUT.PUT_LINE('ORDSourceExceptions.METHOD_NOT_SUPPORTED caught');
            WHEN ORDSYS.ORDDocExceptions.DOC_PLUGIN_EXCEPTION THEN
                DBMS_OUTPUT.put_line('DOC PLUGIN EXCEPTION caught');
        END;
        /
        CALL Insertar_DocsBD(${newID},'${guiones}');
        `;
            
            let doc = undefined;
            if (guiones) {
                doc = guiones;
            } 
            guiones = "ORDSYS.ORDDOC()";
            

            const artist = {
                ID_PELICULA: `${newID}`,
                TITULO: req.body.TITULO,
                ID_DIRECTOR: `${director}`,
                DESCRIPCION: req.body.DESCRIPCION,
                DURACION: req.body.DURACION,
                CREDITOS: "NULL",
                GUIONES: `${guiones}`
            }

            const insertSql =
                `INSERT INTO PELICULAS (ID_PELICULA, TITULO, ID_DIRECTOR, DESCRIPCION, DURACION, CREDITOS, GUIONES) VALUES (${artist.ID_PELICULA}, '${artist.TITULO}', '${artist.ID_DIRECTOR}', '${artist.DESCRIPCION}', ${artist.DURACION}, ${artist.CREDITOS}, ${artist.GUIONES})`;
            const result = await database.simpleExecute(connectionName, insertSql, []);
            console.log(result);

            if (doc) {
                const createProcedure = await database.simpleExecute(connectionName, procedure, []);
                console.log(procedure);
            }

            res.sendStatus(200);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    });

/*
router.route('/artists/:id')

.put(async (req, res) => {

    const artist = {
        artist_cod: parseInt(req.params.id),
        artist_name: req.body.artistName,
        genre: req.body.genre,
        biografy: req.body.biografy

    }

    const updateSql =
        `UPDATE ARTISTS SET
    ARTIST_NAME = :artist_name,
    GENRE = :genre,
    BIOGRAFY = :biografy
    
    WHERE ARTIST_COD = :artist_cod`;

    const result = await database.simpleExecute(connectionName, updateSql, artist);
    console.log(result);
    res.json(result);
})
.delete(async (req, res) => {
    const artist = {
        artist_cod: parseInt(req.params.id)
    }
    const deleteSql =
        `DELETE ARTISTS WHERE ARTIST_COD = :artist_cod`;

    const result = await database.simpleExecute(connectionName, deleteSql, artist);
    console.log(result);
    res.json(result);
});
*/

app.use('/', router);

app.get('/', (req, res) => {
    res.send('Welcome to the Cinema Library!');
});

startup();


async function startup() {
    console.log('Starting application');

    try {
        console.log('Opening connection to databases');

        await database.openConnections();

        console.log('Starting web server');

        app.listen(port, () => {
            console.log('Running on port ' + port);
        });
    } catch (err) {
        console.log('Encountered error', err);

        process.exit(1);
    }

};