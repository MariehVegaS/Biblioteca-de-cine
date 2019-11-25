SET SERVEROUTPUT ON;

DROP TABLE Foto_Pelicula;
DROP TABLE actor_Pelicula;
DROP TABLE cate_Pelicula;
DROP TABLE BandaSonora_Pelicula;
DROP TABLE Cancion_Banda;
DROP TABLE PELICULAS;
Drop table Director;
Drop table Actores;
Drop table Categorias;
Drop table Imagenes;
DROP TABLE AUDIOS;

--Creacion de la tabla--- 
create table Director(
ID_Director varchar2(5),
Nombre varchar2(35),
Edad number(3,0),
CONSTRAINT director_pk PRIMARY KEY (ID_Director));

insert into Director values ('00001', 'Director no especificado', 00);
insert into Director values ('00002', 'Gary Ross',63);
insert into Director values ('00003', 'James Cameron',65);
insert into Director values ('00004', 'Neil Burger', 56);

create table Actores(
ID_Actor varchar2(5),
Nombre varchar2(35),
Edad number(3,0),
CONSTRAINT actor_pk PRIMARY KEY (ID_Actor));

insert into Actores values ('00010', 'Shailene Woodley', 28);
insert into Actores values ('00020', 'Theo James', 34);
insert into Actores values ('00030', 'Ashley Judd', 51);
insert into Actores values ('00040', 'Jai Courtney', 33);
insert into Actores values ('00050', 'Ray Stevenson', 55);
insert into Actores values ('00060', 'Zoë Kravitz', 30);
insert into Actores values ('00070', 'Kate Winslet', 44);
/**/
insert into Actores values ('00080', 'Jennifer Lawrence', 29);
insert into Actores values ('00090', 'Josh Hutcherson', 27);
insert into Actores values ('01010', 'Josh Hutcherson', 27);
insert into Actores values ('01020', 'Liam Hemsworth', 29);
insert into Actores values ('01030', 'Woody Harrelson', 58);
insert into Actores values ('01040', 'Elizabeth Banks', 45);
insert into Actores values ('01050', 'Lenny Kravitz', 55);
insert into Actores values ('01060', 'Donald Sutherland', 84);

insert into Actores values ('01070', 'Sam Worthington', 43);
insert into Actores values ('01080', 'Zoe Saldana', 41);
insert into Actores values ('01090', 'Stephen Lang', 67);
insert into Actores values ('01100', 'Michelle Rodriguez', 41);
insert into Actores values ('01110', 'Sigourney Weaver', 70);

create table Categorias(
ID_Categoria varchar2(5),
descripcion varchar2(20),
CONSTRAINT Catego_pk PRIMARY KEY (ID_Categoria));

insert into Categorias values ('00100', 'Accion');
insert into Categorias values ('00200', 'Drama');
insert into Categorias values ('00300', 'Romance');
insert into Categorias values ('00400', 'Terror');
insert into Categorias values ('00500', 'Fantasia');
insert into Categorias values ('00600', 'Misterio');
insert into Categorias values ('00700', 'Distopicas');
insert into Categorias values ('00800', 'Animadas');
insert into Categorias values ('00900', 'Infantiles');
insert into Categorias values ('00101', 'Policiacas');
insert into Categorias values ('00102', 'Documentales');
insert into Categorias values ('00103', 'Ciencia Ficcion');

create table Imagenes(
Id_Fotos varchar2(5),
IMAGE ordimage NOT NULL,
CONSTRAINT imagenes_pk PRIMARY KEY (Id_Fotos));

CREATE TABLE AUDIOS(
    AUDIO_COD  varchar2(5),
    
    SONG_NAME VARCHAR2(50),
    ARTIST_name VARCHAR2(50),
    SONG    ORDSYS.ORDAUDIO,
    CONSTRAINT audio_pk PRIMARY KEY (AUDIO_COD));

CREATE TABLE PELICULAS(
id_pelicula VARCHAR(5) NOT NULL,
titulo VARCHAR2(30) NOT NULL,
ID_Director VARCHAR(5) NOT NULL,
descripcion VARCHAR(600),
duracion number(3,0),
creditos CLOB,
guiones ORDDOC,
CONSTRAINT peli_PK PRIMARY KEY(id_pelicula),
CONSTRAINT peli_id_direc FOREIGN KEY (ID_Director) REFERENCES Director(ID_Director));

CREATE TABLE Foto_Pelicula(
Id_Fotos VARCHAR(5) NOT NULL,
id_pelicula VARCHAR(5) NOT NULL,
CONSTRAINT foto_id_pelicula FOREIGN KEY (Id_Fotos) REFERENCES Imagenes(Id_Fotos),
CONSTRAINT pelicula_id_foto FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula));

/*PROCEDIMIENTOS PARA IMPORTAR ARCHIVOS(IMAGE, DOCS, AUDIOS)*/
/*IMAGENES*/
create or replace  PROCEDURE image_import(wiCode CHAR, filename VARCHAR2) IS
  img ordsys.ordimage;
  ctx raw(64) := null;
BEGIN

  SELECT IMAGE into img
  FROM Imagenes
  WHERE Id_Fotos = wiCode
  FOR UPDATE;
  
  img.importfrom(ctx, 'FILE', 'MULTIMEDIA', filename);
  UPDATE Imagenes
  SET IMAGE = img
  WHERE Id_Fotos = wiCode;
  
  END;
/
/*DOCS*/
create or replace procedure Insertar_DocsBD(vCodigo CHAR, vArchivo varchar2) IS
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
/*AUDIOS*/
CREATE OR REPLACE PROCEDURE Insertar_SonidoBD(vAudCod number, vArchivo varchar2) IS
  aud ordsys.ordaudio;
  ctx raw(64) := null;
  --audio_cod number;
BEGIN
     SELECT song into aud
     from audios
     where audio_cod = vAudCod
     for update;
    
   aud.importFrom(ctx, 'FILE', 'MULTIMEDIA', vArchivo);
   aud.setProperties(ctx,TRUE);
   --Leyendo propiedades del audio.
   DBMS_OUTPUT.PUT_LINE('Length is: ' || TO_CHAR(aud.getContentLength(ctx)));
    DBMS_OUTPUT.PUT_LINE('Source: ' || aud.getSource());
    DBMS_OUTPUT.PUT_LINE('format: ' || aud.getformat);
    DBMS_OUTPUT.PUT_LINE('encoding: ' || aud.getEncoding);
    DBMS_OUTPUT.PUT_LINE('numberOfChannels: ' || TO_CHAR(aud.getNumberOfChannels));
    DBMS_OUTPUT.PUT_LINE('compressionType : ' || aud.getCompressionType());
    DBMS_OUTPUT.PUT_LINE('samplingRate: ' || TO_CHAR(aud.getSamplingRate));
    DBMS_OUTPUT.PUT_LINE('sampleSize: ' || TO_CHAR(aud.getSampleSize));
    DBMS_OUTPUT.PUT_LINE('audioDuration: ' || TO_CHAR(aud.getAudioDuration()));
    
   UPDATE AUDIOS 
   SET SONG = aud 
   WHERE AUDIO_COD = vAudCod;
     
END;
/

/*INSERTAR DATOS Y ARCHIVOS*/
/*IMAGENES*/
insert into Imagenes values(01001, ordsys.ordimage.init());
call image_import(01001, 'DIVERGENTE_Foto1.jpg');
insert into Imagenes values(01002, ordsys.ordimage.init());
call image_import(01002, 'DIVERGENTE_Foto2.jpg');
insert into Imagenes values(01003, ordsys.ordimage.init());
call image_import(01003, 'DIVERGENTE_Foto3.jpg');
insert into Imagenes values(01004, ordsys.ordimage.init());
call image_import(01004, 'DIVERGENTE_Foto4.jpg');
insert into Imagenes values(01005, ordsys.ordimage.init());
call image_import(01005, 'DIVERGENTE_Foto5.jpg');
insert into Imagenes values(01006, ordsys.ordimage.init());
call image_import(01006, 'DIVERGENTE_Foto6.jpg');
insert into Imagenes values(01007, ordsys.ordimage.init());
call image_import(01007, 'DIVERGENTE_Foto7.jpg');
insert into Imagenes values(01008, ordsys.ordimage.init());
call image_import(01008, 'DIVERGENTE_Foto8.jpg');
insert into Imagenes values(01009, ordsys.ordimage.init());
call image_import(01009, 'DIVERGENTE_Foto9.jpg');
insert into Imagenes values(01011, ordsys.ordimage.init());
call image_import(01011, 'DIVERGENTE_Foto91.jpg');

insert into Imagenes values(02001, ordsys.ordimage.init());
call image_import(02001, 'LOSJUEGOSDELHAMBRE_Foto1.jpg');
insert into Imagenes values(02002, ordsys.ordimage.init());
call image_import(02002, 'LOSJUEGOSDELHAMBRE_Foto2.jpg');
insert into Imagenes values(02003, ordsys.ordimage.init());
call image_import(02003, 'LOSJUEGOSDELHAMBRE_Foto3.jpg');
insert into Imagenes values(02004, ordsys.ordimage.init());
call image_import(02004, 'LOSJUEGOSDELHAMBRE_Foto4.jpg');
insert into Imagenes values(02005, ordsys.ordimage.init());
call image_import(02005, 'LOSJUEGOSDELHAMBRE_Foto5.jpg');
insert into Imagenes values(02006, ordsys.ordimage.init());
call image_import(02006, 'LOSJUEGOSDELHAMBRE_Foto6.jpg');
insert into Imagenes values(02007, ordsys.ordimage.init());
call image_import(02007, 'LOSJUEGOSDELHAMBRE_Foto7.jpg');
insert into Imagenes values(02008, ordsys.ordimage.init());
call image_import(02008, 'LOSJUEGOSDELHAMBRE_Foto8.jpg');
insert into Imagenes values(02009, ordsys.ordimage.init());
call image_import(02009, 'LOSJUEGOSDELHAMBRE_Foto9.jpg');
insert into Imagenes values(02011, ordsys.ordimage.init());
call image_import(02011, 'LOSJUEGOSDELHAMBRE_Foto91.jpg');

insert into Imagenes values(03001, ordsys.ordimage.init());
call image_import(03001, 'AVATAR_Foto1.jpg');
insert into Imagenes values(03002, ordsys.ordimage.init());
call image_import(03002, 'AVATAR_Foto2.jpg');
insert into Imagenes values(03003, ordsys.ordimage.init());
call image_import(03003, 'AVATAR_Foto3.jpg');
insert into Imagenes values(03004, ordsys.ordimage.init());
call image_import(03004, 'AVATAR_Foto4.jpg');
insert into Imagenes values(03005, ordsys.ordimage.init());
call image_import(03005, 'AVATAR_Foto5.jpg');
insert into Imagenes values(03006, ordsys.ordimage.init());
call image_import(03006, 'AVATAR_Foto6.jpg');
insert into Imagenes values(03007, ordsys.ordimage.init());
call image_import(03007, 'AVATAR_Foto7.jpg');
insert into Imagenes values(03008, ordsys.ordimage.init());
call image_import(03008, 'AVATAR_Foto8.jpg');

/*AUDIOS*/
insert into AUDIOS values(10001, 'Beating Heart','Ellie Goulding',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10001, 'DIVERGENTE_ Beating Heart_Ellie Goulding.mp3');
insert into AUDIOS values(10002, 'Big Deal','Dream Machines',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10002, 'DIVERGENTE_Big Deal_Dream Machines.mp3');
insert into AUDIOS values(10003, 'Dead in the water','Ellie Goulding',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10003, 'DIVERGENTE_Dead In the water_Ellie Goulding.mp3');
insert into AUDIOS values(10004, 'Fight for you','Pia feat Chance the rapper',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10004, 'DIVERGENTE_Fight For You_Pia feat Chance the rapper.mp3');
insert into AUDIOS values(10005, 'Hanging on i see monsters','Ellie Goulding',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10005, 'DIVERGENTE_Hanging on i see monsters_Ellie Goulding.mp3');
insert into AUDIOS values(10006, 'I need you','M83',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10006, 'DIVERGENTE_I need you_M83.mp3');
insert into AUDIOS values(10007, 'I wont let you go','Snow Patrol',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10007, 'DIVERGENTE_I wont let you go_Snow Patrol.mp3');
insert into AUDIOS values(10008, 'Pretty Lights','Lost and found',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10008, 'DIVERGENTE_Pretty Lights_Lost and found.mp3');
insert into AUDIOS values(10009, 'Find you','Zedd feat. Matthew Koma y Miriam Bryant',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(10009, 'DVERGENTE_Find You_Zedd feat. Matthew Koma y Miriam Bryant.mp3');

insert into AUDIOS values(20001, 'Atlas','Coldplay',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20001, 'LOSJUEGOSDELHAMBRE_Atlas.m4a');
insert into AUDIOS values(20002, 'Angel on Fires','Antony and the Johnsons',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20002, 'LOSJUEGOSDELHAMBRE_Angel On Fire.m4a');
insert into AUDIOS values(20003, 'Lights','Panthogram',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20003, 'LOSJUEGOSDELHAMBRE_Lights.m4a');
insert into AUDIOS values(20004, 'Place For Us','Mikki Ekko',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20004, 'LOSJUEGOSDELHAMBRE_Place For Us.m4a');
insert into AUDIOS values(20005, 'Shooting Arrows At The Sky','Santigold',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20005, 'LOSJUEGOSDELHAMBRE_Shooting Arrows At the Sky.m4a');
insert into AUDIOS values(20006, 'Capitol Letter','Patti Smith',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20006, 'LOSJUEGOSDELHAMBRE_Capitol Letter.m4a');
insert into AUDIOS values(20007, 'Mirror','Ellie Goulding',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20007, 'LOSJUEGOSDELHAMBRE_Mirror.m4a');
insert into AUDIOS values(20008, 'Gale','The Lumineers',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20008, 'LOSJUEGOSDELHAMBRE_Gale.m4a');
insert into AUDIOS values(20009, 'Everybody Wants To Rule the World','Lorde',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(20009, 'LOSJUEGOSDELHAMBRE_Everybody Wants To Rule the World.mp3');

insert into AUDIOS values(30001, 'You dont dream in Cryo','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30001, 'AVATAR_You Dont Dream In Cryo.mp3');
insert into AUDIOS values(30002, 'Becoming one of the people','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30002, 'AVATAR_Becoming_One_Of_The_People-Becoming_One_With_Neytiri.mp3');
insert into AUDIOS values(30003, 'Climbing Up Iknimaya','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30003, 'AVATAR_Climbing_Up_Iknimaya_-_The_Path_to_Heaven_.mp3');
insert into AUDIOS values(30004, 'Jake Enters His Avatar World','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30004, 'AVATAR_Jake Enters His Avatar World.mp3');
insert into AUDIOS values(30005, 'Jakes First Flight','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30005, 'AVATAR_Jakes_First_Flight_.mp3');
insert into AUDIOS values(30006, 'Pure Spirits of the Forest','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30006, 'AVATAR_Pure Spirits of the Forest.mp3');
insert into AUDIOS values(30007, 'The Bioluminescense of the Night','James Horner',ordsys.ORDAUDIO.init());
call INSERTAR_SONIDOBD(30007, 'AVATAR_The_Bioluminescence of the Night_James_Horner.mp3');


/*DOCS*/
insert into PELICULAS values (10000, 'Divergente','00001','Se desarrolla en el futuro, en una sociedad distópica donde la raza humana está 
dividida en cinco facciones. Cada una de ellas se dedica a cultivar una determinada virtud: Verdad (los sinceros), Abnegación (los altruistas),
Osadía (los valientes), Cordialidad (los pacíficos) y Erudición (los inteligentes). Al cumplir los dieciséis años, Beatrice Prior tiene que 
elegir la facción a la que pertenecerá. Enamorada de un joven, la muchacha se ve obligada a guardar un secreto para evitar que la maten',139,NULL,ORDSYS.ORDDOC());
CALL Insertar_DocsBD(10000,'DIVERGENTE_Guion.docx');

insert into PELICULAS values (20000, 'Los juegos del hambre','00002','Un pasado de guerras ha dejado los 12 distritos que dividen Panem bajo el 
poder tiránico del "Capitolio". Sin libertad y en la pobreza, nadie puede salir de los límites de su distrito. Sólo una chica de 16 años, Katniss 
Everdeen, osa desafiar las normas para conseguir comida.Cuando su hermana pequeña es elegida para participar, Katniss no duda en ocupar su lugar.',
142,NULL,ORDSYS.ORDDOC());
CALL Insertar_DocsBD(20000,'LOSJUEGOSDELHAMBRE_Guion.docx');

insert into PELICULAS values (30000, 'AVATAR','00003','En un futuro muy lejano, cuando Jake Sully (Sam Worthington) es un veterano de guerra que 
ha quedado parapléjico. Es trasladado en medio de su desesperación a Pandora, una luna del planeta Polifemo habitada por una raza humanoide 
llamada navi, con la que los humanos se encuentran en conflicto por: el unobtainium. Pero Sully no llegará a ese lugar con su identidad original, 
con su propia identidad terrestre, ya que, realmente, han proyectado un avatar del marine que es muy diferente en su aspecto.',161,NULL,ORDSYS.ORDDOC());
CALL Insertar_DocsBD(30000,'AVATAR_Guion.docx');

insert into Foto_Pelicula values (01001, '10000');
insert into Foto_Pelicula values (01002, '10000');
insert into Foto_Pelicula values (01003, '10000');
insert into Foto_Pelicula values (01004, '10000');
insert into Foto_Pelicula values (01005, '10000');
insert into Foto_Pelicula values (01006, '10000');
insert into Foto_Pelicula values (01007, '10000');
insert into Foto_Pelicula values (01008, '10000');
insert into Foto_Pelicula values (01009, '10000');
insert into Foto_Pelicula values (01011, '10000');

insert into Foto_Pelicula values (02001, '20000');
insert into Foto_Pelicula values (02002, '20000');
insert into Foto_Pelicula values (02003, '20000');
insert into Foto_Pelicula values (02004, '20000');
insert into Foto_Pelicula values (02005, '20000');
insert into Foto_Pelicula values (02006, '20000');
insert into Foto_Pelicula values (02007, '20000');
insert into Foto_Pelicula values (02008, '20000');
insert into Foto_Pelicula values (02009, '20000');
insert into Foto_Pelicula values (02011, '20000');

insert into Foto_Pelicula values (03001, '30000');
insert into Foto_Pelicula values (03002, '30000');
insert into Foto_Pelicula values (03003, '30000');
insert into Foto_Pelicula values (03004, '30000');
insert into Foto_Pelicula values (03005, '30000');
insert into Foto_Pelicula values (03006, '30000');
insert into Foto_Pelicula values (03007, '30000');
insert into Foto_Pelicula values (03008, '30000');

CREATE TABLE actor_Pelicula(
ID_Actor VARCHAR(5) NOT NULL,
id_pelicula VARCHAR(5) NOT NULL,
CONSTRAINT actor_id_pelicula FOREIGN KEY (ID_Actor) REFERENCES Actores(ID_Actor),
CONSTRAINT pelicula_id_actor FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula));

insert into actor_Pelicula values ('00010', '10000');
insert into actor_Pelicula values ('00020', '10000');
insert into actor_Pelicula values ('00030', '10000');
insert into actor_Pelicula values ('00040', '10000');
insert into actor_Pelicula values ('00050', '10000');
insert into actor_Pelicula values ('00060', '10000');
insert into actor_Pelicula values ('00070', '10000');

insert into actor_Pelicula values ('00080', '20000');
insert into actor_Pelicula values ('00090', '20000');
insert into actor_Pelicula values ('01010', '20000');
insert into actor_Pelicula values ('01020', '20000');
insert into actor_Pelicula values ('01030', '20000');
insert into actor_Pelicula values ('01040', '20000');
insert into actor_Pelicula values ('01050', '20000');
insert into actor_Pelicula values ('01060', '20000');

insert into actor_Pelicula values ('01070', '30000');
insert into actor_Pelicula values ('01080', '30000');
insert into actor_Pelicula values ('01090', '30000');
insert into actor_Pelicula values ('01100', '30000');
insert into actor_Pelicula values ('01110', '30000');

CREATE TABLE cate_Pelicula(
ID_Categoria VARCHAR(5) NOT NULL,
id_pelicula VARCHAR(5) NOT NULL,
CONSTRAINT peli_id_categ FOREIGN KEY (ID_Categoria) REFERENCES Categorias(ID_Categoria),
CONSTRAINT cat_id_pelicula FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula));

insert into cate_Pelicula values ('00100', '10000');
insert into cate_Pelicula values ('00103', '10000');

insert into cate_Pelicula values ('00700', '20000');
insert into cate_Pelicula values ('00100', '20000');
insert into cate_Pelicula values ('00103', '20000');

insert into cate_Pelicula values ('00100', '30000');
insert into cate_Pelicula values ('00500', '30000');
insert into cate_Pelicula values ('00103', '30000');
insert into cate_Pelicula values ('00800', '30000');

CREATE TABLE Cancion_Banda(
id_banda VARCHAR(5) NOT NULL,
nombre_banda VARCHAR2(30) NOT NULL,
CONSTRAINT banda_PK PRIMARY KEY(id_banda));

insert into Cancion_Banda values ('10100', 'DIVERGENTE SOUNDTRACK');
insert into Cancion_Banda values ('10200', 'LOSJUEGOSDELHAMBRE SOUNDTRACK');
insert into Cancion_Banda values ('10300', 'AVATAR SOUNDTRACK');

CREATE TABLE BandaSonora_Pelicula(
id_banda VARCHAR(5),
id_pelicula VARCHAR(5),
AUDIO_COD varchar2(5),
CONSTRAINT banda_id_pelicula FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula),
CONSTRAINT banda_id_cancion_nombre FOREIGN KEY (id_banda) REFERENCES Cancion_Banda(id_banda),
CONSTRAINT banda_id_cancion FOREIGN KEY (AUDIO_COD) REFERENCES AUDIOS(AUDIO_COD));

insert into BandaSonora_Pelicula values ('10100', '10000','10001');
insert into BandaSonora_Pelicula values ('10100', '10000','10002');
insert into BandaSonora_Pelicula values ('10100', '10000','10003');
insert into BandaSonora_Pelicula values ('10100', '10000','10004');
insert into BandaSonora_Pelicula values ('10100', '10000','10005');
insert into BandaSonora_Pelicula values ('10100', '10000','10006');
insert into BandaSonora_Pelicula values ('10100', '10000','10007');
insert into BandaSonora_Pelicula values ('10100', '10000','10008');
insert into BandaSonora_Pelicula values ('10100', '10000','10009');

insert into BandaSonora_Pelicula values ('10200', '20000','20001');
insert into BandaSonora_Pelicula values ('10200', '20000','20003');
insert into BandaSonora_Pelicula values ('10200', '20000','20004');
insert into BandaSonora_Pelicula values ('10200', '20000','20005');
insert into BandaSonora_Pelicula values ('10200', '20000','20006');
insert into BandaSonora_Pelicula values ('10200', '20000','20007');
insert into BandaSonora_Pelicula values ('10200', '20000','20008');
insert into BandaSonora_Pelicula values ('10200', '20000','20009');

insert into BandaSonora_Pelicula values ('10300', '30000','30001');
insert into BandaSonora_Pelicula values ('10300', '30000','30003');
insert into BandaSonora_Pelicula values ('10300', '30000','30004');
insert into BandaSonora_Pelicula values ('10300', '30000','30005');
insert into BandaSonora_Pelicula values ('10300', '30000','30006');
insert into BandaSonora_Pelicula values ('10300', '30000','30007');

/*PROCEDIMIENTOS PARA EXPORTAR ARCHIVOS(IMAGE, DOCS, AUDIOS)*/
/*IMAGENES*/
create or replace procedure imgExport(source_id char, filename varchar2) as
imgSrc ordsys.ordimage;
ctx raw(64) := null;
begin
select IMAGE into imgSrc from Imagenes where Id_Fotos = source_id;
imgSrc.export(ctx, 'FILE', 'EXPORTADO', filename);
end;
/
/*AUDIOS*/
CREATE OR REPLACE PROCEDURE SONIDO_EXPORT(SOURCE_ID NUMBER, FILENAME VARCHAR2) AS
AUDSRC ORDSYS.ORDAUDIO;
CTX RAW(64) := NULL;
BEGIN
SELECT SONG INTO AUDSRC FROM AUDIOS WHERE AUDIO_COD = SOURCE_ID;
AUDSRC.EXPORT(CTX, 'FILE', 'EXPORTADO', FILENAME);
END;
/
/*DOCS*/
create or replace procedure doc_export(source_id char, filename varchar2) as
docSrc ordsys.orddoc;
ctx raw(64) := null;
begin
select guiones into docSrc from PELICULAS where id_pelicula = source_id;
docSrc.export(ctx, 'FILE', 'EXPORTADO', filename);
end;
/
/*EXPORTAR ARCHIVOS*/
CALL imgExport(1001,'IMAGEN_EXPORTADA.jpg');
CALL SONIDO_EXPORT(20001,'AUDIO_EXPORTADO.mp3');
CALL doc_export('30000','GUION_EXPORTADO.doc');
