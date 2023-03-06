CREATE TABLE Peers
(
    Nickname        VARCHAR UNIQUE PRIMARY KEY,
    Birthday        DATE NOT NULL
);

CREATE TABLE Tasks
(
    Title           VARCHAR PRIMARY KEY UNIQUE  NOT NULL,
    ParentTask      VARCHAR                     NOT NULL,
    MaxXP           BIGINT                      NOT NULL CHECK ( MaxXP > 0 )
);

CREATE TYPE check_state AS ENUM ('Start', 'Success', 'Failure');
CREATE TYPE time_tracking_state AS ENUM (1, 2);

CREATE TABLE P2P
(
    ID              SERIAL PRIMARY KEY,
    "Check"         BIGINT                      NOT NULL,
    CheckingPeer    VARCHAR                     NOT NULL,
    State           check_state                 NOT NULL,
    "Time"          TIME                        NOT NULL
);

CREATE TABLE Verter
(
    ID              SERIAL PRIMARY KEY,
    "Check"         BIGINT                      NOT NULL,
    State           check_state                 NOT NULL,
    "Time"          TIME                        NOT NULL
);

CREATE TABLE Checks
(
    ID              SERIAL PRIMARY KEY,
    Peer            VARCHAR                     NOT NULL,
    Task            VARCHAR                     NOT NULL,
    "Date"          DATE                        NOT NULL
);

CREATE TABLE TransferredPoints
(
    ID              SERIAL PRIMARY KEY,
    CheckingPeer    VARCHAR                     NOT NULL,
    CheckedPeer     VARCHAR                     NOT NULL,
    PointsAmount    BIGINT                      NOT NULL
);

CREATE TABLE Friends
(
    ID              SERIAL PRIMARY KEY,
    Peer1           VARCHAR                     NOT NULL,
    Peer2           VARCHAR                     NOT NULL
);

CREATE TABLE Recommendations
(
    ID              SERIAL PRIMARY KEY,
    Peer            VARCHAR                     NOT NULL,
    RecommendedPeer VARCHAR                     NOT NULL
);

CREATE TABLE XP
(
    ID              SERIAL PRIMARY KEY,
    "Check"         BIGINT                      NOT NULL,
    XPAmount        BIGINT                      NOT NULL
);

CREATE TABLE TimeTracking
(
    ID              BIGINT PRIMARY KEY,
    Peer            VARCHAR                     NOT NULL,
    "Date"          DATE                        NOT NULL,
    "Time"          TIME                        NOT NULL,
    State time_tracking_state                   NOT NULL
);
