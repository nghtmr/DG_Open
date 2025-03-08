"""django_core URL Configuration
The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.1/topics/http/urls/
"""
from django.contrib import admin
from django.urls import include, path
from django.http import FileResponse
import os

# Direct file serving view
def serve_index(request):
    # Path to your index.html file
    index_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'index.html')
    if os.path.exists(index_path):
        return FileResponse(open(index_path, 'rb'))
    else:
        # Fallback message if file not found
        from django.http import HttpResponse
        return HttpResponse("Welcome to the app! The homepage file was not found.")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("api.urls")),
    
    # Serve index.html at the root URL using our custom view
    path("", serve_index),
]
