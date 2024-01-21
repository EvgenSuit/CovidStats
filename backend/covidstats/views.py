from rest_framework.decorators import api_view
from rest_framework.response import Response
import pandas as pd
import requests

covid_data_dir = 'data/'
covid_data_link = 'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv'
data_dir = covid_data_dir + 'data.csv'
location = 'World'
columns = ['location', 'date', 'total_cases', 'new_cases']
target_year = '2023'


@api_view(['GET'])
def get_covid_data(request):
    # download_data()
    df = pd.read_csv(data_dir)[columns]
    df.dropna(inplace=True)

    rows_up_to_date = []
    last_sp = df.iloc[-1][1].split('-')
    rows = df.iterrows()
    del df
    for i, row in rows:
        sp = row[1].split('-')
        span_of_month = int(sp[1]) >= int(last_sp[1]) - 1
        span_of_month_in_days = int(sp[2]) >= int(last_sp[2]) or (
            (int(last_sp[2]) >= int(sp[2])) and int(sp[1]) == int(last_sp[1]))
        if sp[0] == target_year and span_of_month and span_of_month_in_days:
            rows_up_to_date.append(row)
    df_up_to_date = pd.DataFrame(columns=columns, data=rows_up_to_date)

    df_up_to_date = df_up_to_date[df_up_to_date['location'] == location]

    return Response(df_up_to_date.to_numpy())


def download_data():
    resp = requests.get(covid_data_link)
    with open(data_dir, '+wb') as f:
        f.write(resp.content)
    del resp
