package com.knovik.skillvault.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.knovik.skillvault.ui.resume_list.ResumeListScreen
import com.knovik.skillvault.ui.search.SearchScreen
import com.knovik.skillvault.ui.import_data.ImportDataScreen
import com.knovik.skillvault.ui.benchmarks.BenchmarksScreen
import com.knovik.skillvault.ui.model_manager.ModelManagerScreen
import com.knovik.skillvault.ui.theme.EdgeTalTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main Activity for EdgeTal app.
 * Uses Jetpack Compose with bottom navigation.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            EdgeTalTheme {
                MainScreen()
            }
        }
    }
}

/**
 * Navigation destinations.
 */
sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    data object ResumeList : Screen("resume_list", "Resumes", Icons.Filled.Home)
    data object Search : Screen("search", "Search", Icons.Filled.Search)
    data object Benchmarks : Screen("benchmarks", "Benchmarks", Icons.Filled.Build)
    data object Models : Screen("models", "Models", Icons.Filled.Settings)
    data object ImportData : Screen("import_data", "Import", Icons.Filled.Add)
    data object ResumeDetails : Screen("resume_details/{resumeId}?query={query}&segmentId={segmentId}", "Details", Icons.Filled.Info)
}

/**
 * Main screen with bottom navigation.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val items = listOf(Screen.ResumeList, Screen.Search, Screen.Benchmarks, Screen.Models)
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                
                items.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any { 
                        it.route?.startsWith(screen.route.substringBefore("/")) == true 
                    } == true
                    
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = screen.title) },
                        label = { Text(screen.title) },
                        selected = selected,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.ResumeList.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.ResumeList.route) {
                ResumeListScreen(
                    onNavigateToImport = {
                        navController.navigate(Screen.ImportData.route)
                    }
                )
            }
            composable(Screen.Search.route) {
                SearchScreen(
                    onNavigateToDetails = { resumeId, query, segmentId ->
                        val route = "resume_details/$resumeId?query=$query&segmentId=$segmentId"
                        navController.navigate(route)
                    }
                )
            }
            composable(Screen.Benchmarks.route) {
                BenchmarksScreen()
            }
            composable(Screen.Models.route) {
                ModelManagerScreen()
            }
            composable(Screen.ImportData.route) {
                ImportDataScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onImportSuccess = { navController.popBackStack() }
                )
            }
            composable(
                route = Screen.ResumeDetails.route,
                arguments = listOf(
                    androidx.navigation.navArgument("resumeId") { type = androidx.navigation.NavType.LongType },
                    androidx.navigation.navArgument("query") { 
                        type = androidx.navigation.NavType.StringType
                        nullable = true
                        defaultValue = null
                    },
                    androidx.navigation.navArgument("segmentId") { 
                        type = androidx.navigation.NavType.StringType 
                        nullable = true
                        defaultValue = null
                    }
                )
            ) {
                com.knovik.skillvault.ui.resume_details.ResumeDetailsScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToModels = {
                        navController.navigate(Screen.Models.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                        }
                    }
                )
            }
        }
    }
}
