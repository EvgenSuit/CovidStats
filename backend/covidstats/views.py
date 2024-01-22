from rest_framework.decorators import api_view
from rest_framework.response import Response
import pandas as pd
import requests
import tailer
import io

covid_data_dir = 'data/'
covid_data_link = 'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv'
data_dir = covid_data_dir + 'data.csv'
location = 'World'
columns = ['location', 'date', 'total_cases', 'new_cases']
target_year = '2023'


@api_view(['GET'])
def get_covid_data(request):
    download_data()
    with open(data_dir) as f:
        last_lines = tailer.tail(f, 20)
    df = pd.read_csv(io.StringIO('\n'.join(last_lines)), header=None)
    column_indices = list(range(2, 6))
    df = df[column_indices]
    df.dropna(inplace=True)
    print(df)
    # df.dropna(inplace=True)

    # df_up_to_date = df_up_to_date[df_up_to_date['location'] == location]
    return Response(df.to_numpy())


def download_data():
    resp = requests.get(covid_data_link)
    with open(data_dir, '+wb') as f:
        f.write(resp.content)
    # del resp
