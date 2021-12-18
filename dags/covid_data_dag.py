import os
from datetime import datetime

import pandas as pd
from airflow import DAG
from airflow.contrib.hooks.fs_hook import FSHook
from airflow.hooks.mysql_hook import MySqlHook
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.models import Variable
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
from structlog import get_logger

logger = get_logger()


dag = DAG('project_covid_dag', description='DAG Covid data',
          default_args={
              'owner': 'Juan.Romero',
              'depends_on_past': False,
              'max_active_runs': 1,
              'start_date': days_ago(5)
          },
          schedule_interval='0 1 * * *',
          catchup=False)

FILE_CONNECTION_NAME = 'fs_default'
CONNECTION_DB_NAME = 'mysql_default'

FILE_CONFIRMED = 'time_series_covid19_confirmed_global.csv'
FILE_DEATHS = 'time_series_covid19_deaths_global.csv'
FILE_RECOVERED = 'time_series_covid19_recovered_global.csv'

def process_file(**kwargs):
    logger.info(kwargs["execution_date"])
    file_path = FSHook(FILE_CONNECTION_NAME).get_path()
    #mysql_connection = MySqlHook(mysql_conn_id=CONNECTION_DB_NAME).get_sqlalchemy_engine()

    full_path_confirmed = f'{file_path}/{FILE_CONFIRMED}'
    full_path_deaths = f'{file_path}/{FILE_DEATHS}'
    full_path_recovered = f'{file_path}/{FILE_RECOVERED}'

    df_confirmed = pd.read_csv(full_path_confirmed, encoding="ISO-8859-1")
    df_deaths = pd.read_csv(full_path_deaths, encoding="ISO-8859-1")
    df_recovered = pd.read_csv(full_path_recovered, encoding="ISO-8859-1")

    #logger.info(df_confirmed)
    #logger.info(df_deaths)
    #logger.info(df_recovered)


    df_confirmed_new = pd.melt(df_confirmed, id_vars=['Province/State', 'Country/Region', 'Lat', 'Long'],
                               var_name='fecha',
            value_name="confirmed")

    df_deaths_new = pd.melt(df_deaths, id_vars=['Province/State', 'Country/Region', 'Lat', 'Long'],
                            var_name='fecha', value_name="death")

    df_recovered_new = pd.melt(df_recovered, id_vars=['Province/State', 'Country/Region', 'Lat', 'Long'],
                            var_name='fecha',
                            value_name="recovered")

    logger.info(df_confirmed_new)
    logger.info(df_deaths_new)
    logger.info(df_recovered_new)
    #logger.info(df_final)

    df_confirmed_new = df_confirmed_new.rename(
        columns={'Province/State': 'Estado', 'Country/Region': 'Pais'}, inplace=False)

    df_deaths_new = df_deaths_new.rename(
        columns={'Province/State': 'Estado', 'Country/Region': 'Pais'}, inplace=False)

    df_recovered_new = df_recovered_new.rename(
        columns={'Province/State': 'Estado', 'Country/Region': 'Pais'}, inplace=False)

    df_tmp = pd.merge(df_confirmed_new, df_deaths_new, on=['Pais', 'Estado', 'Lat' , 'Long', 'fecha'],how='left' )

    df_final = pd.merge(df_tmp, df_recovered_new, on=['Pais', 'Estado', 'Lat', 'Long', 'fecha'], how='left')

    mysql_connection = MySqlHook(mysql_conn_id=CONNECTION_DB_NAME).get_sqlalchemy_engine()


    with mysql_connection.begin() as connection:
        stmt = "SHOW TABLES LIKE 'test.confirmed'"
        cursor = connection.execute(stmt)
        result = cursor.fetchone()
        if result:
            connection.execute("DELETE FROM test.confirmed WHERE 1=1")
        stmt = "SHOW TABLES LIKE 'test.deaths'"
        cursor = connection.execute(stmt)
        result = cursor.fetchone()
        if result:
            connection.execute("DELETE FROM test.deaths WHERE 1=1")

        stmt = "SHOW TABLES LIKE 'test.recovered'"
        cursor = connection.execute(stmt)
        result = cursor.fetchone()
        if result:
            connection.execute("DELETE FROM test.recovered WHERE 1=1")

        stmt = "SHOW TABLES LIKE 'test.all_data'"
        cursor = connection.execute(stmt)
        result = cursor.fetchone()
        if result:
            connection.execute("DELETE FROM test.all_data WHERE 1=1")


        df_confirmed_new.to_sql('confirmed', con=connection, schema='test', if_exists='append', index=False)
        df_deaths_new.to_sql('deaths', con=connection, schema='test', if_exists='append', index=False)
        df_recovered_new.to_sql('recovered', con=connection, schema='test', if_exists='append', index=False)
        df_final.to_sql('all_data', con=connection, schema='test', if_exists='append', index=False)


sensor = FileSensor(filepath='time_series_covid19_confirmed_global.csv',
                    fs_conn_id='fs_default',
                    task_id='check_for_file',
                    poke_interval=5,
                    timeout=60,
                    dag=dag
                    )

etl = PythonOperator(task_id="process_file",
                     provide_context=True,
                     python_callable=process_file,
                     dag=dag
                     )

sensor >> etl