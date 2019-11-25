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
        const binds = {};
        const query = `SELECT ID_PELICULA, TITULO
        FROM PELICULAS`;
        try {
            const result = await database.simpleExecute(connectionName, query, []);
            console.log(result);
            res.json(result.rows);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {

        const artist = {
            ID_PELICULA: req.body.ID_PELICULA,
            TITULO: req.body.TITULO, 
            ID_DIRECTOR: req.body.ID_DIRECTOR, 
            DESCRIPCION: req.body.DESCRIPCION, 
            DURACION: req.body.DURACION, 
            CREDITOS: "NULL", 
            GUIONES: "ORDSYS.ORDDOC()"
        }
        //ORDSYS.ORDDOC()
        const insertSql =
            `INSERT INTO PELICULAS (ID_PELICULA, TITULO, ID_DIRECTOR, DESCRIPCION, DURACION, CREDITOS, GUIONES) VALUES (${artist.ID_PELICULA}, '${artist.TITULO}', '${artist.ID_DIRECTOR}', '${artist.DESCRIPCION}', ${artist.DURACION}, NULL, ORDSYS.ORDDOC())`;
        /*HACIENDO USO DE UN PROCEDIMIENTO PREVIAMENTE CREADO EN LA BASE DE DATOS
        const createSql =
        `BEGIN Insertar_ImagenBD(:artist_name, :genre, :biografy, :img_name); END;`;*/

        
        try {
            const result = await database.simpleExecute(connectionName, insertSql, []);
            console.log(result);
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