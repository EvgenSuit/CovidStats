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
    download_data()
    df = pd.read_csv(data_dir)[columns]
    df.dropna(inplace=True)

    return Response("HELLO")


def download_data():
    resp = requests.get(covid_data_link)
    with open(data_dir, '+wb') as f:
        f.write(resp.content)
    del resp
