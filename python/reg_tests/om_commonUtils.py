from __future__ import print_function
# This file defines testing methods that match those in commonUtils.py, 
# but that execute using the OpenMDAO wrapper instead of bare ADflow

from mpi4py import MPI
from mdo_regression_helper import *

from commonUtils import defaultFuncList, defaultAeroDVs, adflowDefOpts, \
                        pyWarpDefOpts, pyWarpUStructDefOpts, printHeader, parPrint

from openmdao.api import Problem 
from openmdao.devtools.testutil import assert_rel_error


def assert_funcs_equal(test, ap, prob, funcs, tolerance):
    evalFuncs = sorted(ap.evalFuncs)

    for f_name in evalFuncs:
        adflow_name = '{}_{}'.format(ap.name, f_name)
        om_name = 'functionals.{}'.format(f_name)
        # print('func compare', f_name, funcs[adflow_name])
        assert_rel_error(test, prob[om_name], funcs[adflow_name], tolerance=tolerance)


def adjointTest(CFDSolver, ap):

    # this call is needed to initialize the state and resid vectors
    state_size = CFDSolver.getStateSize()

    for dv in defaultAeroDVs:
        ap.addDV(dv)

    res = CFDSolver.getResidual(ap)
    totalR0 = CFDSolver.getFreeStreamResidual(ap)
    res /= totalR0
    
    funcsSens = {}
    CFDSolver.evalFunctionsSens(ap, funcsSens)

    return res, funcsSens
   

def solutionAdjointTest(CFDSolver, ap, solve):

    # this call is needed to initialize the state and resid vectors
    state_size = CFDSolver.getStateSize()

    if solve:
        # We are told that we must first solve the problem, most likely
        # for a training run. 
        CFDSolver(ap)


    # Check the residual
    res = CFDSolver.getResidual(ap)
    totalR0 = CFDSolver.getFreeStreamResidual(ap)
    res /= totalR0
  
    funcs = {}
    # CFDSolver.evalFunctions(ap, funcs, defaultFuncList)
    funcs = {}
    CFDSolver.evalFunctions(ap, funcs, defaultFuncList)

    # Get and check the states
    states = CFDSolver.getStates()

    funcsSens = {}
    CFDSolver.evalFunctionsSens(ap, funcsSens)

    return states, res, funcs, funcsSens