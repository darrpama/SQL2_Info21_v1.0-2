CREATE TABLE Peers
(
    Nickname VARCHAR PRIMARY KEY,
    Birthday DATE NOT NULL
);

CREATE TABLE Tasks
(
    Title VARCHAR PRIMARY KEY,
    ParentTask VARCHAR,
    MaxXP BIGINT NOT NULL
);

CREATE TYPE check_state AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE P2P
(
    ID BIGINT PRIMARY KEY,
    "Check" BIGINT NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    State check_state NOT NULL,
    "Time" TIME NOT NULL
);

CREATE TABLE Verter
(
    ID BIGINT PRIMARY KEY,
    "Check" BIGINT NOT NULL,
    State check_state NOT NULL,
    "Time" TIME NOT NULL
);

CREATE TABLE Checks
(
    ID BIGINT PRIMARY KEY,
    Peer VARCHAR NOT NULL,
    Task VARCHAR NOT NULL,
    "Date" DATE NOT NULL
);

CREATE TABLE TransferredPoints
(
    ID BIGINT PRIMARY KEY,
    CheckingPeer VARCHAR NOT NULL,
    CheckedPeer VARCHAR NOT NULL,
    PointsAmount BIGINT NOT NULL
);
